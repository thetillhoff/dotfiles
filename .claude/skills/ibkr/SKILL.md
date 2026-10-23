---
name: ibkr
description: Use when you write or debug code that talks to Interactive Brokers (IBKR) through ib_insync or the IB gateway - orders, positions, account values, connection loss, readiness probes. Triggers - "ib_insync", "IB gateway", "orderId", "permId", "NetLiquidation", "IBKR".
---

# IBKR with ib_insync

- Requests of `ib_insync` have no timeout. A request that never gets an answer blocks the thread that pumps the event loop. Add a liveness endpoint that fails when the worker loop stops, so the probe restarts the pod. `RequestTimeout` alone keeps the loop running on a dead connection.
- IBKR restarts `orderId` at 1 in every gateway session. Only `permId` is stable. Never match or cancel orders by `orderId` across sessions.
- Account tags differ: `NetLiquidation` is the equity, `TotalCashValue` is the cash that is not invested, `AvailableFunds` is `EquityWithLoanValue - initial margin`. `ExchangeRate` rows mean "multiply to reach BASE". Derive the direction (the base currency has rate 1.0).
- `position * averageCost` is negative for a short position.
- A read helper that logs and returns `[]` on a lost connection makes "no open orders" and "not connected" look the same. Check `isConnected()` before you compare broker state with local state.
