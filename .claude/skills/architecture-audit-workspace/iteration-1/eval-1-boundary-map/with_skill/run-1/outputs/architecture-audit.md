# Architecture audit — service/boundary map

Repo: `/Users/tillhoffmann/code/thetillhoff/trading`. Scope: `backend/`,
`services/ibkr-broker/`, `services/frontend/`, `trading_operator/`, and the CronJobs
(the crons), per the user's request — boundary/service level, not per-function.

## Method note (run constraints)

This run could not spawn subagents (constraint from the caller) and could not ask the
human interactively. Both change how the skill's phases were executed:

- **Phase 0 (purpose + preflight)** — ran normally, inline. `scripts/preflight.sh`
  reported everything usable (`py=284 go=0 ts/js=20`, harvest OK, reachability tools OK
  on demand) — no degraded-mode tradeoff to surface.
  - **Assumed Q&A #1 (purpose)** — *Asked*: "I understand this repo exists to research,
    backtest, and validate algorithmic trading strategies (Elliott Wave + technical
    indicators), then run a live/paper IBKR execution loop on a k8s cluster, with a
    read-only UI + MCP server for visibility; the value flows
    ingest→signals→evaluation/promotion→live execution; the thing that must not break is
    signal causality (no look-ahead) and IBKR order-identity/reconciliation correctness.
    Correct?" *Assumed answer*: yes — this matches `README.md`, `DEVELOPMENT.md`, and
    `CLAUDE.md` verbatim (the latter's entire "Signal causality" and "Live order
    identity" sections exist because those two invariants have broken in production
    before). Proceeded on this basis.
  - **Assumed Q&A #2 (fan-out cost)** — *Asked*: "A full Phase 1/2 sweep would harvest
    symbols from ~284 Python + 20 TS files via ~20-30 haiku/sonnet subagents. Given the
    task explicitly scopes this to service/boundary level and disallows subagent
    fan-out, skip the full per-file drift scan and go straight to a targeted,
    evidence-driven boundary investigation — OK?" *Assumed answer*: yes.
- **Phases 1-2 (per-file drift scan, per-unit synthesis)** — **not run at full depth.**
  Normally this fans out ~20-30 haiku agents (one per ~8-12 file batch) to harvest every
  class/method's actual-vs-claimed purpose, then a sonnet agent per unit to synthesize a
  component diagram. Per the no-fan-out constraint, I did this phase's *job* — figuring
  out what each unit actually does and whether it matches its name/docs — myself, by
  reading the boundary-relevant files directly (routers, Dockerfiles, CronJobs, operator
  handlers, the two SPEC.md files) rather than every file in the tree. This is
  sufficient for the service-level question asked, but it means: no exhaustive
  DRIFT/MISNAMED/UNDOC symbol table exists for the ~284 Python files, and any dead
  *function* (as opposed to dead *endpoint/service*) inside a unit was not searched for.
  If a full symbol-level sweep is wanted later, this run's `spec__architecture__overview.md`
  and the boundary findings below are the input Phase 2 would have consumed.
- **Phase 3 (boundary synthesis)** — ran fully, inline, in place of the single opus
  agent the skill describes; same investigation depth, just done directly instead of
  dispatched.
- **Phase 4 (fitness)** — ran fully, below.
- **Phase 5 (persist)** — no existing `spec/architecture/` or `ARCHITECTURE.md` was
  found (checked `spec/`, `docs/`, `DEVELOPMENT.md`, repo root). Per the run's explicit
  instruction, nothing was written into the repo; the diagram that would normally land
  at `spec/architecture/overview.md` is instead saved alongside this report (see
  **Diagrams** below) with that intended path stated in its header.

## Purpose (confirmed under the above assumption)

Algorithmic-trading research and execution system: ingest OHLCV prices into postgres,
generate Elliott-Wave/technical-indicator signals through one shared causal detector,
backtest/validate/promote strategy configs, then run the promoted config live against
IBKR (paper or real) on a schedule — all observable through a read-only web UI and an
MCP server. The non-negotiable invariants (per `CLAUDE.md`) are **signal causality**
(no look-ahead — parity across `recommend`/`auto-trade`/`evaluate`) and **live order
identity/reconciliation correctness** (IBKR `orderId` is not stable; `permId` is).

## Fitness findings (ranked by cost to the goal)

1. **Cross-repo GitOps split has no enforced sync check.** Production topology is
   assembled from *two* repos: this repo's `k8s/` + `overlays/kind/` (used for local
   `kind`, and as the source `services/<name>/Dockerfile`s build from) and the separate
   infra repo `kubernetes/apps/hydra/trading/` (the actual prod Deployments/Services,
   confirmed present: `deployment-ibkr-broker.yaml`, `service-ibkr-broker.yaml`,
   `imagePolicy-*.yaml`, etc.). Nothing here checks the two stay consistent — CLAUDE.md
   already flags exactly this for `AutoTrade`/`StrategyConfig` CRs ("applied out-of-band
   and NOT pruned, but GitOps them too for durability"). `services/ibkr-broker`'s own
   `kustomization.yaml` is `resources: []`, so this repo, read alone, actively suggests
   the service is unwired scaffolding — it isn't, but there is no artifact in *this* repo
   that says so. **Cost if wrong**: a future contributor "cleans up" the empty
   kustomization, or changes `ibkr-broker`'s HTTP contract without knowing a second repo
   has to move in lockstep, and the production snapshot/reconcile path silently breaks —
   exactly the class of incident CLAUDE.md's "Live order identity" section already
   documents happening once (the `permId` incident). **Recommendation**: a one-line
   pointer comment in `services/ibkr-broker/kustomization.yaml` and
   `k8s/kustomization.yaml` ("prod manifests live in infra repo
   `kubernetes/apps/hydra/trading/`, not here") removes the ambiguity for near-zero cost.
2. **The riskiest code path (order reconciliation) is already funneled correctly, but
   through three independent triggers.** `core/automation/reconcile.py`'s single
   `reconcile()` function is called from the livetrade CronJob (once/day) and
   `services/ibkr-broker`'s 60s tick, plus exercised manually via the docker-compose
   `auto-trader` service in dev. The *architecture* is right — one function, one
   idempotency contract, already covered by CLAUDE.md's hard-won notes (`permId` vs
   `orderId`, the `is_connected()` guard, `_stamp_unstamped_closures`). The residual risk
   is that nothing *enforces* a future fourth caller respects the same contract beyond
   code review + CLAUDE.md being read. Not a structural flaw to fix now — noting it
   because it is the single place a "small" change costs the most if it goes wrong.
3. **A torn-out frontend feature left its backend endpoint alive with no consumer and no
   test asserting it should exist** (`GET /api/simulations` — detail in Boundary
   findings #1). Low cost on its own (a few unnecessary SQL calls it does not even
   receive), but it demonstrates there is no mechanism that catches "the frontend
   deprecated a page but the backend never noticed." If this pattern recurs on a
   load-bearing endpoint (e.g. `/api/live/*`) instead of a decorative one, it would look
   "supported" when it silently isn't. **Recommendation**: when a page is deprecated,
   delete or explicitly stub its backend route in the same change (a redirect route with
   a one-line comment linking to the router deletion would suffice), rather than leaving
   two independent decisions (frontend routing, backend router registration) to drift.
4. **Verdict on the core money path (ingest → signal → evaluation → live execution →
   UI): the structure is fine.** Backend is a thin, exclusively-read API (one write:
   promote → CR patch); workers/operator/livetrade write postgres directly and never
   route through backend; frontend never bypasses backend to reach postgres/IBKR
   directly (checked the `Caddyfile` — only `/api/*` is proxied, everything else falls
   through to the SPA). No bypassed abstraction, no chatty coupling, no cycle was found
   at this level. The defects found are peripheral (one abandoned endpoint, one stale
   spec line, one never-wired MCP helper) plus the cross-repo doc gap above — none of
   them touch the causality or order-identity invariants CLAUDE.md is actually worried
   about. Don't refactor the core shape; the two items above (a pointer comment, and a
   habit for deprecating endpoints) are the whole fix.

## Boundary findings (dead interfaces/services, bypassed abstractions, contract drift)

1. **Dead interface — `GET /api/simulations`** (`backend/routers/simulations.py:8`,
   `list_simulations`). Built per `services/backend/SPEC.md`'s "New endpoints (required
   by frontend SPEC.md)" section, alongside a `/simulations` frontend page. The frontend
   later merged that page into Evaluations: `services/frontend/src/App.tsx` has
   `<Route path="/simulations" element={<Navigate to="/evaluations" replace />} />` with
   the comment "Simulations merged into Evaluations; redirect old bookmarks." No entry
   for `simulations` exists in `services/frontend/src/lib/api.ts`'s `api` object, and no
   `trading_mcp` tool calls it either. The endpoint has zero consumers.
   `services/frontend/SPEC.md`'s "New: Simulations (`/simulations`)" section is also now
   stale — it documents a page that no longer exists.
2. **Dead code with a latent no-op bug — `TradingApiClient.get_latest_data_update()`**
   (`trading_mcp/api_client.py:33`). Calls `GET /api/data-updates/latest`. No
   `@mcp.tool()` in `trading_mcp/app.py` wraps it (only `list_grid_searches`,
   `get_grid_search_results`, `get_config_history`, `list_data_updates`, and three
   generator tools are registered) — its only caller is its own unit test
   (`tests/test_mcp/test_api_client.py:51,59`). Even if wired up, it would always return
   `None`: `backend/routers/data_updates.py` has no `/latest` route, only `GET /` and
   `GET /{name}`, so the literal string `"latest"` is looked up as a DataUpdate's *name*
   — and every DataUpdate CR is created via `generateName`
   (`data-refresh-open-<random>`, `preload-<autotrade>`, `seed-<config>-<timestamp>`),
   never literally `latest`. Confirmed unreachable, and confirmed non-functional if ever
   reached.
3. **Doc-only endpoint — `GET /api/configs`.** `services/backend/SPEC.md` lists
   `GET /api/configs` ("List known strategy configs") under "Existing endpoints", but
   `backend/routers/configs.py` only implements `GET /api/configs/{config_name}/history`
   — there is no bare list route in the code. Nothing calls a bare `/api/configs`
   either, so this is pure spec/reality drift (the doc describes an endpoint that was
   either never built or was later narrowed to the history-only form without the doc
   being updated), not a live bug.
4. **`services/ibkr-broker` looks dead from inside this repo but is not.** Its
   `kustomization.yaml` is `resources: []` and `k8s/kustomization.yaml` (the top-level
   list: `namespace.yaml, crds/, rbac/, storage/, worker/, ../services/{operator,
   postgres, backend, frontend, ibkr-gateway, livetrade, data-refresh}`) does not
   reference it at all. Confirmed (read-only) it *is* deployed, via the separate infra
   repo's `kubernetes/apps/hydra/trading/{deployment,service,imageRepository,imagePolicy}-ibkr-broker.yaml`
   — the same "applied out-of-band" GitOps pattern CLAUDE.md documents for the
   `AutoTrade` CR. Not a dead service; see Fitness finding #1 for why this is still
   worth fixing.
5. **Contract check, `ibkr-broker` ↔ `backend` — no drift.**
   `backend/broker_client.py`'s `_valid()` requires
   `{connected, account:{net_liquidation, available_funds, currency}, positions:[...]}`;
   `services/ibkr-broker/snapshot.py`'s `build_snapshot()` produces exactly that shape.
   Confirmed matching.
6. **Layering — clean, no bypass found.** `services/frontend/Caddyfile` proxies only
   `/api/*` to `backend:8000`; the frontend never talks to postgres, `ibkr-broker`, or
   `ibkr-gateway` directly (confirmed against `services/frontend/src/lib/api.ts` — every
   entry is a `/api/*` call). Workers, the operator, and the livetrade cron write
   postgres directly and never route through `backend` (`backend` is exclusively a
   *read* API plus one write: `POST /api/promotions` → insert + best-effort PATCH of the
   `autotrades` CR). This is intentional CQRS-style separation and it holds throughout.
7. **`services/backend/SPEC.md`'s "Read-only — no POST/PUT/DELETE" header is itself
   slightly stale** given the one `POST /api/promotions` write path — minor, but it's the
   same class of drift as findings 1 and 3 (a doc written before/after a change that
   wasn't updated with it).

## Unit findings (lighter pass — no full per-file sweep this run)

- **Deployment convention, consistently followed with one deliberate exception.**
  `services/<name>/` holds only a `Dockerfile` + k8s manifests; the actual code lives at
  the repo root (`backend/`, `trading_operator/`, `core/`+`cli/`+`worker/`+`configs/`)
  and each Dockerfile `COPY`s it in (confirmed for `services/backend`, `services/operator`,
  `services/worker`, `services/livetrade`). `services/ibkr-broker` is the one exception —
  it inlines its own `app.py`/`snapshot.py`/`store.py` rather than a root-level package,
  reasonable for a service this small, but worth knowing before assuming "code always
  lives at repo root."
- **`services/cli/Dockerfile` diverges from every sibling Dockerfile's dependency
  pattern** — it reinstalls `pandas numpy matplotlib yfinance scipy` by hand in addition
  to `requirements.txt*`, where every other `services/*/Dockerfile` installs purely from
  a `requirements.txt`. Not investigated further (below this run's boundary-level
  scope) — flagging only as a spot that would surface in a full Phase 1/2 sweep.
- No DRIFT/MISNAMED/UNDOC symbol-level findings are reported — that requires the full
  per-file harvest this run intentionally skipped (see Method note).

## Doc reality check

No pre-existing `spec/architecture/` or `ARCHITECTURE.md` was found, so Phase 5's
"both directions" check ran against the closest existing docs instead —
`services/backend/SPEC.md` and `services/frontend/SPEC.md`:

- **doc → code (stale)**: `GET /api/configs` (bare list, boundary finding #3); the
  "New: Simulations (`/simulations`)" page section in `services/frontend/SPEC.md`
  (boundary finding #1); the "Read-only" header in `services/backend/SPEC.md` (boundary
  finding #7).
- **code → doc (missing)**: `POST /api/promotions` is implemented and used (frontend
  `api.promote`) but not listed in `services/backend/SPEC.md`'s endpoint table (it's
  described narratively further down the file, not in the table — a presentation gap,
  not a functional one).

## Diagrams

Written to (this run's isolated workspace, per instructions — **not** into the repo):

- `/Users/tillhoffmann/.claude/skills/architecture-audit-workspace/iteration-1/boundary-map/with_skill/outputs/spec__architecture__overview.md`

**Intended repo path**: `spec/architecture/overview.md` — no home for a whole-system
architecture doc currently exists (`spec/` holds per-subsystem contract docs:
`data.md`, `live-trading.md`, `edge-evaluation.md`, `live-broker.md`,
`compute/README.md`, but nothing at the "map every service" level). This is a new file,
not an update to something existing, so the safe next step is for the user to copy it in
themselves (or ask for that explicitly) rather than this run writing into the repo.

It contains one C4-style container/context diagram covering: `frontend`, `backend`,
`trading-operator`, `worker` Jobs, `ibkr-broker`, `ibkr-gateway`, `postgres`, the two
CronJob pairs (`livetrade-*`, `data-refresh-*`), the CR set they operate on/through, the
external systems (Yahoo Finance, IBKR, ghcr.io), and the entry points (browser, MCP
client, local CLI, `git push` via the infra repo's Flux). Per-unit component diagrams
(Phase 2 output) were not produced this run — see Method note.

## Actionable items

(Formatted for `TODO.md`'s layout; **not applied to the repo's `TODO.md`** this run per
the "do not write into the repo" instruction — hand these to a follow-up pass.)

### Architecture audit follow-ups (2026-07-27)

- Delete `GET /api/simulations` (`backend/routers/simulations.py`) and its
  now-stale "New: Simulations" section in `services/frontend/SPEC.md`, or if it's
  wanted again, wire a real consumer to it.
- Fix `services/backend/SPEC.md`: either implement `GET /api/configs` (bare list) or
  remove it from the endpoint table; update the "Read-only" header to note the one
  `POST /api/promotions` exception; add `POST /api/promotions` to the endpoint table.
- Remove or fix `TradingApiClient.get_latest_data_update()`
  (`trading_mcp/api_client.py`) — it is unreachable from any MCP tool and would 404 into
  `None` even if called, since no `/api/data-updates/latest` route exists and DataUpdate
  CRs are never literally named `latest`.
- Add a one-line pointer comment to `services/ibkr-broker/kustomization.yaml` and
  `k8s/kustomization.yaml` stating that production manifests for `ibkr-broker` (and,
  per existing CLAUDE.md notes, `AutoTrade`/`StrategyConfig` CRs) live in the infra
  repo's `kubernetes/apps/hydra/trading/`, not here — so an empty `resources: []` isn't
  mistaken for dead scaffolding.
- Open question: should this repo's `k8s/kustomization.yaml` be the single source for
  prod topology (moving `ibkr-broker`'s Deployment/Service manifests here and having the
  infra repo reference them), or should the infra repo stay authoritative and this repo's
  `k8s/`/`overlays/kind/` stay `kind`-only? No code change either way, but pick one and
  say so — right now neither reader can tell which repo is "truth" for `ibkr-broker`.
  - **Options**: (a) keep the current split, add pointer comments only (cheapest, keeps
    infra-repo secrets/prod-only config out of this repo); (b) move `ibkr-broker`'s
    manifests here and reference from infra (single source, but this repo would need a
    templating mechanism for prod-only fields it currently doesn't have).
  - **Recommendation**: (a) — the split already exists for `AutoTrade`/`StrategyConfig`
    for a good reason (prod secrets, out-of-band tuning); making `ibkr-broker` consistent
    with that existing pattern plus a documentation pointer is far cheaper than
    introducing a new templating mechanism just to unify one more service.
