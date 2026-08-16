# Does `core/` structurally weaken execution or returns?

Yes. One structural gap dominates everything else found: **the live execution path does not share the sizing/risk engine that the backtest validates the strategy against.** Signal generation is shared (by design, and carefully guarded per `CLAUDE.md`); everything downstream of "we have a signal, now size and manage it" is a second, independent, much poorer implementation. A secondary, related finding is a scattered `getattr(config, ..., <hardcoded literal>)` pattern whose fallback literals have already drifted from the real config defaults in several places.

## Finding 1 (headline): live orders are sized by a different law than the one the strategy was validated with

**The code.**

- `core/evaluation/portfolio.py::PortfolioSimulator._compute_position_size` (lines 261-343) is a genuine sizing *engine*: it supports `sizing_mode` (`equal_weight` / `confidence_tilt` / legacy confidence-scaled / `risk_parity`), `reserve_slots` (slot size = `total_portfolio_value / (n_open + reserve_slots)`), `use_confidence_sizing`, `use_confirmation_modulation` + `confirmation_size_factors`, `use_volatility_sizing` (+ threshold + reduction), `use_flexible_sizing` (+ method + target R:R), and a `max_allocation_pct_per_instrument` cap, on top of `max_positions`. `core/evaluation/walk_forward.py::_portfolio_simulator_from_config` (lines 84-122) threads **26** `StrategyConfig` fields into this engine, with the docstring "Single place for sim config."
- `core/broker/order_builder.py::OrderBuilder.build_order_from_signal` (the code that actually builds a live IBKR order) computes position size as one line: `position_size_usd = available_capital * self.position_size_pct` (line 111). `confidence_score` is carried through only as a logged/reported field (`signal_certainty`) — it never touches the size calculation. `OrderBuilder` has no constructor parameter for `sizing_mode`, `reserve_slots`, or any of the other 22 sizing/risk fields listed above.
- Both live entrypoints that construct `OrderBuilder` (`cli/livetrade_cycle.py:131` and `cli/auto_trade.py:245`) pass exactly two values: `position_size_pct` and `min_position_size`. `cli/auto_trade.py:244` even comments "all sizing/risk params come from the strategy config" — which is false; only 2 of 26 do. That comment is itself evidence the mismatch was introduced silently, not by choice.
- Confirmed by grep that `sizing_mode`, `reserve_slots`, `trailing_stop_pct`, `use_volatility_sizing`, `max_allocation_pct_per_instrument`, `confirmation_size_factors`, `use_flexible_sizing`, `use_confidence_sizing`, `bankruptcy_threshold`, `max_participation_pct`, and `impact_coef` appear **zero times** anywhere under `core/broker/` or `core/automation/`.
- `max_positions` is likewise never read in `core/automation/trader.py`. `AutomatedTrader.should_skip_signal` (line 322) only blocks a *duplicate* order or position on the *same* ticker; it never counts total open positions against a cap. `analyze_and_trade` (line 371) also only ever places **one** trade per cycle (breaks on the first candidate that passes order-builder validation), so there is no code path that would even consult `max_positions` if it were wired through.
- `trailing_stop_pct` (line 1400 of `portfolio.py`) has no live counterpart at all — a live bracket order's stop/target are static once placed.

**Why this matters, concretely, not hypothetically.** `TODO.md` (line 122) names the current validated strategy: `configs/champion/ew-champion.yaml` — **`equal_weight` sizing mode with `reserve_slots=10`**. Per `CLAUDE.md`'s own research notes, `equal_weight` sizing (full slot regardless of confidence) is explicitly called "a genuine optimum" for this signal, and the standard enhancement levers (confidence-sizing, trailing/reversal exits, risk-parity) were tried and rejected. That means the number the strategy is *supposed* to produce comes from slot-based equal-weight sizing across up to 10 reserved slots. The code that places real orders cannot express any of that: it always sizes off flat `position_size_pct × NetLiquidation`, with no concept of a slot, no cap on concurrent positions, and no confidence weighting. Whatever the backtest number is, live capital deployment does not implement the strategy that produced it — it implements a materially simpler and differently-risked one. This is the reason live returns cannot be expected to track the validated backtest once real capital compounds across several concurrent positions.

**Root cause (shape, not a one-off bug).** There is no shared `PositionSizer`/risk-engine abstraction that both `core/evaluation` and `core/broker` + `core/automation` depend on. `core/signals/detector.py` is carefully protected for causal parity (per `CLAUDE.md`, with dedicated truncation-invariance tests) precisely because it is shared between live and sim — but nothing plays that role for sizing or exit management. The sizing/risk engine was built only inside the sim package and never extracted, so the live package re-derived its own (much thinner) version from scratch, and the two have quietly diverged with no test to catch it (unlike signal parity, which has explicit parity tests per `CLAUDE.md`'s "Parity across entry points" rule — written for signals only, not sizing).

**What would fix the shape** (not prescribing exact code): extract `_compute_position_size` (and the trailing-stop/exit logic) out of `PortfolioSimulator` into a module that both `core/evaluation` and `core/broker`/`core/automation` import and call identically, the same way `core/signals/detector.py` is already shared. Add a parity test analogous to the existing signal-parity ones, asserting a given `StrategyConfig` + snapshot of open positions produces the same order size whether it goes through `analyze_and_trade` or `PortfolioSimulator`.

## Finding 2 (secondary, systemic): `getattr(config, key, <literal-default>)` is a scattered anti-pattern whose literals have already drifted from the real defaults

There are 127 `getattr(config, ...)` call sites across `core/signals/`, `core/evaluation/`, `core/indicators/`, `core/orchestration/`, and `core/asset_analysis/`. `StrategyConfig`/`SignalConfig` (`core/signals/config.py`) are plain dataclasses — every field already has one canonical default sourced from `core/shared/defaults.py`. The `getattr` calls re-type a second, independent default at each call site. Concretely, in `core/signals/detector.py` (lines 53-62), these hardcoded fallbacks have already diverged from the real config defaults:

| field | `detector.py` getattr fallback | actual default |
|---|---|---|
| `rsi_period` | 7 | 14 |
| `rsi_oversold` | 25 | 30 |
| `rsi_overbought` | 75 | 70 |
| `macd_signal` | 12 | 9 |

Today these are dead values — every real caller (`core/signals/actionable_signals.py` and `core/evaluation/walk_forward.py::_signal_config_from_strategy`, which correctly imports the shared constants) passes a fully-populated config object, so the fallback never fires. But that's the danger: nothing enforces it stays that way. A field rename, a partial/duck-typed config in a new caller, or a refactor touching `detector.py`'s `getattr` key without touching `config.py` would silently change strategy behavior with no error — grep found no test asserting these getattr defaults track the dataclass defaults. This is the same shape of failure `CLAUDE.md` already documents once elsewhere (the StrategyConfig YAML round-trip bug that silently loaded defaults) — the 127 getattr-with-relit-literal sites are that failure mode built into the code's shape in a dozen more places.

**Fix shape**: replace `getattr(config, 'x', <literal>)` with plain `config.x` (the dataclasses guarantee the attribute and its real default) or, where duck-typing is required, source the fallback from the same `shared/defaults.py` constant the dataclass field uses.

## Checked and ruled out

- Whether live sizing's `available_capital` (`NetLiquidation`) is a semantic mismatch against sim's `total_portfolio_value` basis — it isn't; both use total portfolio value as the sizing base.
- Trade cost/slippage config (`trade_fee_*`, `slippage_*_bps`) is absent from `core/broker` too, but that's correct — those model real broker costs for backtest realism; the live broker charges real costs natively.

## Scope note

This audit covers `core/` only. Finding 1's gap is fully diagnosable within `core/` (`core/evaluation/portfolio.py` vs `core/broker/order_builder.py` + `core/automation/trader.py`); the two call sites instantiating `OrderBuilder` with only 2 of 26 sizing fields live in `cli/`, outside `core/`, cited only to confirm the gap is real end-to-end.

---

Harness note: the subagent's file-write tool refused the requested path, so this text was persisted by the parent session instead.
