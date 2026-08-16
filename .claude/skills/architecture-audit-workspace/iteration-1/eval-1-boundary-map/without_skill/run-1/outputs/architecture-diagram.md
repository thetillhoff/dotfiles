# Trading system — container/boundary map

Destined for `DEVELOPMENT.md` under "Distributed compute & live trading" (that
section currently describes this only in prose — see `spec/README.md` for the
existing higher-altitude flowchart it would sit alongside). Written here
instead per this run's constraint not to write into the repo.

```mermaid
flowchart TB
  UI["Operator UI\nReact SPA"]

  subgraph frontendSvc["frontend service"]
    Caddy["Caddy\nstatic files + /api/* proxy"]
  end

  Backend["backend\nFastAPI, read-only"]
  PG[("Postgres\nsingle source of truth")]

  subgraph alwaysOnCrons["always-on CronJobs"]
    DRO["data-refresh-open\ndata-refresh-close\ncreate DataUpdate CR"]
  end

  subgraph liveCrons["livetrade CronJobs\nsuspend flag flipped by operator"]
    LTOpen["livetrade-open (09:32 ET)"]
    LTClose["livetrade-close (16:30 ET)"]
  end

  Operator["trading-operator\nkopf reconcile loop"]
  IBKRBroker["ibkr-broker\nwarm snapshot + reconcile\n+ wallet ticker\n(prod only — deployed from\nthe infra repo, not this repo's k8s/)"]
  IBKRGateway["ibkr-gateway\nIBKR TWS/paper API proxy"]

  subgraph workerJobs["ephemeral worker Jobs (one pod per task)"]
    WDownload["download"]
    WPlanning["planning"]
    WSignals["signals"]
    WSimulation["simulation"]
  end

  MCP["trading_mcp\nlocal MCP server for Claude\n(runs on host, outside the cluster)"]
  CLIAuto["cli/auto_trade.py\n+ core.automation.state.StateManager\ndocker-compose 'auto-trader' only\nNOT deployed to k8s"]

  UI -->|HTTP GET| Caddy
  Caddy -->|reverse_proxy /api/*| Backend
  Backend -->|SQL read| PG
  Backend -->|GET /snapshot, /health| IBKRBroker

  DRO -->|kubectl create| Operator
  Operator -->|creates Job| WDownload
  Operator -->|creates Job, on GridSearch CR| WPlanning
  WPlanning -->|creates TaskPlan CR| Operator
  Operator -->|creates Jobs per task, throttled| WSignals
  Operator -->|creates Jobs per task, throttled| WSimulation
  WDownload -->|writes prices| PG
  WSignals -->|writes results| PG
  WSimulation -->|writes results| PG

  Operator -->|patches suspend, from\nAutoTrade CR + StrategyConfig.column| LTOpen
  Operator -->|patches suspend| LTClose
  LTOpen -->|cli.livetrade_cycle:\nplace/cancel orders| IBKRGateway
  LTClose -->|cli.livetrade_cycle| IBKRGateway
  LTOpen -->|PgStateManager:\norders/fills/trade_log| PG
  LTClose -->|PgStateManager| PG

  IBKRBroker -->|warm read connection| IBKRGateway
  IBKRBroker -->|reconcile + append wallet point| PG

  MCP -->|GET /api/configs/name/history| Backend

  CLIAuto -.->|legacy parallel path, dev-only,\nnever touches Postgres| IBKRGateway

  classDef dead stroke:#c0392b,stroke-width:2px,stroke-dasharray: 4 2;
  class CLIAuto dead
```

## Legend

- Solid arrow = live, confirmed-reachable edge.
- Dashed red = reachable only from local dev tooling / tests, not from any
  deployed environment — a parallel path, not part of the production system.

## What's NOT dead despite looking it at first glance

- **`ibkr-broker`** has an empty `kustomization.yaml` (`resources: []`) in
  *this* repo's `k8s/`, and no `deployment.yaml`/`service.yaml` here at all —
  a repo-only reader would call it dead. It is deployed and wired
  (`readinessProbe` on `/health`, `backend`'s `IBKR_BROKER_URL` pointing at
  it) from the **separate infra repo**
  (`~/code/thetillhoff/infra/kubernetes/apps/hydra/trading/`), because the
  local `kind` overlay has no real IBKR connection to warm-cache. Both its
  endpoints (`/snapshot`, `/health`) are live.
