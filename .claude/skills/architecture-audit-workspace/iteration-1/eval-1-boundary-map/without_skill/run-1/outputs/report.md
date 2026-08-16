# Boundary map: backend/, services/ibkr-broker/, services/frontend/, trading_operator/, crons

Read-only investigation across `/Users/tillhoffmann/code/thetillhoff/trading` plus the sibling infra repo (`~/code/thetillhoff/infra`), which turned out to hold the actual production k8s manifests for this app. Nothing was written into the trading repo.

## Purpose (as documented)

A signal-driven trading system: market data (Postgres, single source) feeds a shared signal detector, which feeds both distributed compute (k8s operator + worker Jobs → wallet + walletless evaluations) and a live paper/live trading engine, both surfaced through a read-only operator UI. The standing invariant: causality (truncation invariance) between live and backtest signal generation, and parity across `make recommend` / `make auto-trade` / `make evaluate`.

## Boundary findings

### 1. Dead interface: `GET /api/simulations`

`backend/routers/simulations.py` defines `list_simulations()`, mounted in `backend/main.py`. No caller anywhere: not `services/frontend/src/lib/api.ts` (no `simulations` entry), not `trading_mcp`, not tests. The frontend even signals the page was retired — `App.tsx` redirects `/simulations` straight to `/evaluations` via a `Navigate` route. The route component is gone; the backend endpoint and its SQL query were left behind. Safe to delete `backend/routers/simulations.py` and its `app.include_router(simulations.router)` line in `backend/main.py`.

By contrast, `backend/routers/configs.py`'s `GET /api/configs/{name}/history` looks identical (no frontend caller either) but is **not dead** — `trading_mcp/api_client.py:get_config_history` calls it, exercised by `tests/test_mcp/test_api_client.py`. Same shape, only one is actually unused.

### 2. `ibkr-broker` looks orphaned in this repo, but isn't

`services/ibkr-broker/kustomization.yaml` is `resources: []`, with no `deployment.yaml`/`service.yaml` in this repo — unlike every sibling under `services/`. `k8s/kustomization.yaml` never references `ibkr-broker` either. Read in isolation, this looks like a service whose image is built (`.github/workflows/build-images.yml`) and deployed nowhere.

It is in fact live in production: the infra repo (`~/code/thetillhoff/infra/kubernetes/apps/hydra/trading/deployment-ibkr-broker.yaml` + `service-ibkr-broker.yaml`) deploys it, `backend.yaml` there wires `IBKR_BROKER_URL=http://ibkr-broker:8002`, and a `readinessProbe` hits `/health`. Both endpoints (`/snapshot`, `/health`) are genuinely reachable — just not from anything committed to this repo's `k8s/` tree, which only models the local `kind` overlay (no real IBKR connection there to warm-cache). This split isn't documented anywhere in this repo; worth a one-line pointer so nobody "fixes" the empty kustomization by deleting the directory.

### 3. A legacy parallel automation stack, reachable only from local dev

`cli/auto_trade.py` (385 lines, `ThreadPoolExecutor`-based long-running loop) is a second, independent automated-trading implementation, separate from the one `CLAUDE.md` extensively documents (permId reconciliation, `live_orders`/`live_fills`/`live_trade_log`, `PgStateManager`, `core.automation.reconcile`):

- Uses `core.automation.state.StateManager` — a JSON-**file**-based order tracker — not `core.automation.pg_state.PgStateManager`, which the entire production live-trading path depends on (`cli/livetrade_cycle.py`, `ibkr-broker`'s reconcile ticker, backend's `/api/live/*` routes).
- Never calls `core.automation.reconcile.reconcile`, the function `CLAUDE.md` names as the single source of truth for order-vs-broker reconciliation.
- Invoked only by `docker-compose.yml`'s `auto-trader` service (`command: python cli/auto_trade.py`) / `make auto-trade`, and exercised only by `tests/test_cli/test_auto_trade.py`. Not deployed to Kubernetes anywhere — grepped across both this repo's `k8s/` and the infra repo, `auto_trade` only appears in `docker-compose.yml`.
- Writes to a local JSON file, not Postgres — anything run through it is invisible to the backend/UI (`live_status`, `live_orders`, `live_positions`, wallet series) and to `ibkr-broker`.

Production automation instead runs: `AutoTrade` CR → `trading_operator/handlers/autotrade.py` (flips `livetrade-open`/`livetrade-close` CronJob `suspend` based on the active `StrategyConfig`'s `column`) → the unsuspended CronJob → `cli/livetrade_cycle.py` → `core.automation.trader.AutomatedTrader` + `PgStateManager`. `cli/auto_trade.py` sits beside that whole path, unused in any deployed environment, kept alive only by `docker-compose` and its own test — a second implementation of the same job that has silently diverged from the documented production behavior (no reconcile, file-based state). Anyone running `make auto-trade` expecting production behavior would be surprised.

### No other dead services

- `services/frontend` → Caddy (`services/frontend/Caddyfile`) reverse-proxies `/api/*` to `backend:8000`, serves the SPA otherwise; every route in `App.tsx` has a real component.
- `backend` → Postgres directly, and `ibkr-broker` via `backend/broker_client.py` (`fetch_snapshot`, degrades to `None` on any failure by design, callers fall back to Postgres).
- `trading_operator` has exactly one kopf handler per CRD kind defined in `k8s/crds/`: `dataupdates`, `gridsearches`, `taskplans`, `strategyconfigs`, `autotrades` — no orphaned handler, no unhandled CRD.
- The two always-on crons (`data-refresh-open`/`close`) create `DataUpdate` CRs consumed by the operator's `data_update.py` handler into a `download` worker Job.
- `worker/__main__.py` dispatches all four `TASK_TYPE`s the operator's `trading_operator/jobs.py` can produce (`download`, `planning`, `signals`, `simulation`) — full coverage both ways.

## Unit-level notes

- `trading_operator/handlers/job_completion.py`'s `reconcile_task_plan` (kopf timer, 10s) and `grid_search.py`'s `reconcile_waiting_for_data` (kopf timer, 30s) are the native-controller polling loops `CLAUDE.md`'s "k8s operator / grids" section refers to — both wired to real CRD kinds.
- `trading_mcp/` (MCP server for Claude, run on the host outside Docker per its README) is a legitimate third consumer of the backend API alongside the frontend — worth naming since it's the edge that keeps `/api/configs/*/history` alive (see finding 1).

## Diagrams

Saved to `outputs/architecture-diagram.md` (mermaid C4-style container diagram of every edge above, plus a legend marking the one dead-in-production path).

It belongs in the repo at **`DEVELOPMENT.md`**, under the existing "Distributed compute & live trading" section (currently prose-only) — per this repo's own docs convention (`DEVELOPMENT.md` = the architecture doc). `spec/README.md` already carries a higher-altitude flowchart (`data → signals → compute/live → ui`); this diagram sits one level below it, at the service/container level. Not applied to the repo in this run (write constraint).

## Suggested follow-ups (not applied — judgement calls)

- Delete `backend/routers/simulations.py` + its `include_router` line in `backend/main.py`.
- Add a one-line pointer in `services/ibkr-broker/kustomization.yaml` or `spec/live-broker.md` noting its manifests live in the infra repo.
- Decide `cli/auto_trade.py`'s fate: retire it (and `docker-compose`'s `auto-trader` service + `make auto-trade`) in favor of `cli/livetrade_cycle.py` locally, or explicitly label it a local-only simulation harness that intentionally doesn't share state with production.

---

Harness note: the subagent's file-write tool refused the requested path, so this text was persisted by the parent session instead. The diagram file it did write is alongside this report.
