# Architecture overview — container/boundary map

> Intended repo path: `spec/architecture/overview.md` (this run did not write into the
> repo; see the accompanying `report.md` for why and for the full findings).

Scope: service/boundary level only (C4 "container" tier — deployables, datastores,
external systems, entry points). No per-file/component diagrams were produced this run
(see report §Method).

## System context

```mermaid
flowchart TB
    subgraph external["External systems"]
        yahoo["Yahoo Finance\n(yfinance)"]
        ibkrReal["IBKR\npaper/live account"]
        ghcr["ghcr.io\nimage registry"]
    end

    subgraph humans["Entry points"]
        browser["Browser\n(operator)"]
        mcpClient["MCP client\n(Claude Desktop/agent)"]
        devCli["Local CLI\n(make evaluate/recommend/...)"]
        gitPush["git push\n(this repo)"]
    end

    subgraph infraRepo["infra repo (separate)\nkubernetes/apps/hydra/trading/"]
        flux["FluxCD"]
    end

    subgraph cluster["hydra k8s cluster — namespace: trading"]
        frontend["frontend\nCaddy + React SPA"]
        backend["backend\nFastAPI read API"]
        operator["trading-operator\nkopf controller"]
        worker["worker Jobs\n(download/planning/signals/simulation)"]
        ibkrBroker["ibkr-broker\nFastAPI + warm IB session"]
        ibkrGateway["ibkr-gateway\n(3rd-party IB Gateway image)"]
        postgres[("postgres\nprices, results, edge_results,\nlive_*, grid_searches, data_updates")]
        cronLivetrade["CronJobs:\nlivetrade-open / livetrade-close\n(cli.livetrade_cycle)"]
        cronDataRefresh["CronJobs:\ndata-refresh-open / -close\n(kubectl create DataUpdate)"]
        crs["CRs: AutoTrade, StrategyConfig,\nGridSearch, TaskPlan, DataUpdate"]
    end

    browser -->|"/ (static)"| frontend
    frontend -->|"/api/* reverse_proxy"| backend
    mcpClient -->|"HTTP GET /api/*"| backend
    devCli -.->|"local, bypasses cluster"| postgres

    gitPush --> flux
    flux -->|applies CRs + Deployments,\nincl. ibkr-broker| cluster

    cronDataRefresh -->|"kubectl create DataUpdate"| crs
    crs -->|"kopf watch"| operator
    operator -->|"create Job"| worker
    operator -->|"suspend/unsuspend"| cronLivetrade
    operator -->|"write status"| postgres
    worker -->|"yfinance fetch\n(core.data.ingest)"| yahoo
    worker -->|"write results/edge_results/\ndata_updates"| postgres

    cronLivetrade -->|"read StrategyConfig/AutoTrade CR"| crs
    cronLivetrade -->|"read prices, write live_orders/\nlive_cycles/live_signals"| postgres
    cronLivetrade -->|"place orders"| ibkrGateway
    ibkrBroker -->|"warm session:\nreconcile + wallet series"| ibkrGateway
    ibkrBroker -->|"write live_positions/\nlive_fills/live_portfolio"| postgres
    backend -->|"read-only SQL"| postgres
    backend -->|"GET /snapshot\n(fallback: DB)"| ibkrBroker
    backend -->|"PATCH AutoTrade CR\n(on promote)"| crs
    ibkrGateway -.->|"FIX/TWS API"| ibkrReal

    ghcr -.->|"images"| cluster
```

## Notes on this diagram

- **`ibkr-broker` is not wired in this repo's own `k8s/kustomization.yaml`** — its local
  `services/ibkr-broker/kustomization.yaml` is `resources: []`. Its Deployment/Service
  live only in the separate infra repo
  (`kubernetes/apps/hydra/trading/{deployment,service}-ibkr-broker.yaml`), the same
  GitOps split CLAUDE.md documents for the `AutoTrade` CR. It is real and running in
  production, just invisible if you only read this repo. See report §Boundary findings.
- **Local dev path** (`docker-compose.yml`: `postgres`, `cli`, `ibkr-gateway`,
  `auto-trader`) is a second, smaller topology used for iteration — it talks to the same
  `core/` code but never touches the cluster, the operator, or `ibkr-broker`.
- `trading_mcp` is not a deployed service; it's a local MCP wrapper (mounted into the
  `cli` compose service) that calls the backend's public `/api/*` over HTTP, same as the
  browser does.
