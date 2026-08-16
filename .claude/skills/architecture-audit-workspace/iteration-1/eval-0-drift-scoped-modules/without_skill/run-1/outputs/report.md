# Architecture audit: `core/automation` and `core/signals`

Scope: every file under `core/automation/` (`__init__.py`, `state.py`, `pg_state.py`, `reconcile.py`, `scheduler.py`, `trader.py`) and `core/signals/` (`__init__.py`, `config.py`, `config_loader.py`, `rules.py`, `detector.py`, `detector_filters.py`, `target_calculator.py`, `actionable_signals.py`). Read every line of every file (5,188 total) plus cross-referenced every public symbol against the rest of the repo (`cli/`, `services/`, `tests/`) with `grep` to confirm live vs. dead. No code was changed.

## Headline finding: `core/signals/rules.py` is a fully orphaned parallel implementation

`rules.py` defines a `SignalRule` protocol plus `RsiRule`, `EmaRule`, `MacdRule`, and `get_technical_rules()`. Its module docstring claims: "New rules can be added without changing detector logic." This is not true of the current system. `SignalDetector.detect_signals_with_indicators` never calls `get_technical_rules()` — it imports it (`detector.py:28`) but the import is unused. Instead, `SignalDetector._get_technical_indicator_signals` (`detector.py:251-371`) hand-rolls its own vectorized re-implementation of the *exact same* RSI/EMA/MACD crossover logic that `rules.py` already expresses as pluggable classes. The two implementations happen to agree today, but nothing enforces that — adding a new `SignalRule` subclass has **zero effect on real signal generation**, silently.

Confirmed via grep: `get_technical_rules` and the rule classes are referenced nowhere in production code, only in `tests/test_signals/test_rules.py`. The whole module — protocol, docstring, and re-export in `core/signals/__init__.py.__all__` — is dead weight kept alive purely by its own unit test.

## `core/signals` findings

### Dead code

- **`BaselineConfig`** (`config.py:598-640`) — helper class, zero references anywhere in the repo including tests. Fully dead.
- **`get_actionable_signals_for_date`** + `ActionableSignalsResult` (`actionable_signals.py:205-283`) — superseded in production by `get_execution_day_candidates_for_instrument` (used by `cli/recommend.py` and `core/automation/trader.py`). Now exercised only by `tests/test_signals/test_temporal_invariance.py`. Its helper `ew_confirmation_window` is only reachable through it.
- **`SignalDetector.detect_signals`** (`detector.py:71-74`) — thin wrapper, no production caller (only `test_detector.py`); the real pipeline always calls `detect_signals_with_indicators` directly.
- **`SignalDetector._filter_signals_by_multi_timeframe`** (`detector.py:176-215`) — a second, independent implementation of the MTF confirmation filter. The real pipeline does its own inline MTF-filter logic in `detect_signals_with_indicators` (lines 148-160); this method is never called from there, surviving only because tests call the private method directly.
- **`SignalDetector._deduplicate_signals`** (`detector.py:893-895`) — unused wrapper around the module-level `deduplicate_signals`; zero callers anywhere.

### Docstring/naming vs. behavior

- **`AutomatedTrader.rank_signals`** docstring lists a 3-key sort priority, but delegates to `execution_candidate_sort_key`, which sorts on 5 keys (adds instrument and signal-type tie-breakers). Incomplete, not wrong.
- **`TargetCalculator`** class docstring says "Calculates target prices for trading signals" but every call also produces the stop-loss.
- **`BASELINE_CONFIG`/`PRESET_CONFIGS`** carry hard-coded performance claims in comments (`"+45.75% alpha"`, "best win rate: 49.1%") from a 2026-01-24 hypothesis test that predate both the MTF-causality fix and the dead-on-arrival entry fix (which alone drops win rate 44.6%→25.6% per `CLAUDE.md`). The claim baked into the code is now stale/overstated; `CLAUDE.md`'s own convention says such claims belong in `HYPOTHESIS_TEST_RESULTS.md`, not source comments.

### Structural: config round-trip is not exhaustively guarded

Comparing the full `StrategyConfig` field list against `save_config_to_yaml`'s output dict, these fields are **not serialized** and silently reset to their dataclass default across a save→load round trip: `use_atr_stops`, `atr_stop_multiplier`, `atr_period`, `max_days`, `use_confirmation_modulation`, `confirmation_size_factors`, `max_participation_pct`, `adv_window`, `adv_stat`, `impact_coef`.

`tests/test_signals/test_config_roundtrip.py` asserts only a curated subset of fields by hand rather than iterating every `StrategyConfig` field, so it would not catch a regression in any of the ten fields above, nor a future field added and forgotten (exactly the failure mode `CLAUDE.md` already flags as having happened once). Separately, `use_atr_stops`/`atr_stop_multiplier`/`atr_period`/`max_days` aren't even read *from* YAML on load, so ATR-based stops are wired all the way to `TargetCalculator` but structurally unreachable from any YAML-driven strategy config — only a direct Python `StrategyConfig(...)` construction (tests) can set them.

### Minor design smell

`_validate_config` (`config.py:57-100`) is shared between `StrategyConfig.__post_init__` and `SignalConfig.__post_init__`, but `SignalConfig` has no `risk_reward`/`position_size_pct` fields — its `__post_init__` passes hard-coded dummy values just to satisfy a validator that doesn't really apply to it.

## `core/automation` findings

### `StateManager`'s documented responsibility is not the one that runs

The class docstring lists "Prevent duplicate orders for same instrument/day" as a responsibility. Grepping every production caller shows `has_order_for_instrument_today`, `get_orders_for_date`, `get_all_instruments_with_orders_today`, and `update_order_status` are **never called** by `AutomatedTrader`, `reconcile()`, `cli/auto_trade.py`, or `cli/livetrade_cycle.py`. They're fully implemented and unit-tested in isolation, but duplicate-order prevention actually happens in `AutomatedTrader.should_skip_signal`, which asks IBKR directly — a completely separate mechanism from the one the class's own docstring advertises.

### `PgStateManager`'s "drop-in" claim hides a real feature gap between the two live-trading paths

Two parallel production entry points exist: local/dev (`docker-compose`'s `auto-trader`, `make auto-trade`) runs `cli/auto_trade.py` → `Scheduler` + JSON `StateManager`; production/hydra runs `cli/livetrade_cycle.py` (via k8s CronJobs in `services/livetrade/`) → `PgStateManager`, no `Scheduler`. Both feed the same `AutomatedTrader.analyze_and_trade`, which guards every Postgres-only feature with `hasattr(self.state_manager, ...)`: `append_signal`, `set_signal_decisions`, `append_portfolio_snapshot`, `upsert_position`, `update_signal_traded`, `append_trade_log`, `load_active_orders`, `load_unstamped_closures`, `record_fill`. None exist on the JSON `StateManager`, so the local/dev path silently runs a materially degraded feature set (no skip-reason recording, no portfolio snapshots, no trade-log outcome stamping, no position mirroring) with no warning anywhere. `PgStateManager`'s docstring ("drop-in for StateManager") overstates the substitutability.

### `OrderStatus.CANCELLED` is an unreachable enum member

Defined in `state.py:22` and queried in `PgStateManager.load_unstamped_closures` (`status IN ('closed','cancelled')`), but nothing anywhere ever writes that status — only `pending→filled`, `pending→closed`, `filled→closed` transitions exist. That query branch currently never matches.

### Minor duplication

`AutomatedTrader.should_skip_signal` recomputes long/short quantity inline, duplicating the logic already extracted into `_long_position_qty_for_instrument` (used elsewhere in the same class).

### Checked, ruled out (not a problem)

- `reconcile.py` is clean and internally consistent — accurate docstrings, single source of truth (`classify_outcome`), idempotent writes.
- `core/automation/__init__.py`'s lazy PEP 562 export shim is intentional and correctly documented.
- `Scheduler` is internally consistent with its one caller (`cli/auto_trade.py`).

## Recommendations, in priority order

1. Resolve `rules.py` vs. `detector.py`'s inline duplicate logic — wire the detector to actually use `get_technical_rules()`, or delete the module.
2. Delete confirmed-dead code: `BaselineConfig`, `get_actionable_signals_for_date`/`ActionableSignalsResult`/`ew_confirmation_window` (migrate `test_temporal_invariance.py` first), `SignalDetector.detect_signals`, `_filter_signals_by_multi_timeframe`, `_deduplicate_signals`.
3. Make the config round-trip test exhaustive (iterate `dataclasses.fields(StrategyConfig)`), then either wire the ten missing fields into `save_config_to_yaml` or explicitly document them as Python-construction-only.
4. Fix or document the `StateManager` docstring re: duplicate-order prevention.
5. Make the `auto_trade.py`/`livetrade_cycle.py` feature gap explicit in a comment or `TODO.md` entry.

---

Harness note: the subagent's file-write tool refused the requested path, so this text was persisted by the parent session instead.
