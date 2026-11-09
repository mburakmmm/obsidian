# ADR-0015: bounded callback lifecycle

- Status: accepted for the Phase 10 synchronous core
- Date: 2026-11-09

## Context

The synchronous dispatcher calls user-provided filters and sinks. The original log re-entry guard stopped a callback from logging recursively, but route mutation could still grow the live dispatch list while it was being traversed. Sink `flush` and `close` callbacks could also invoke the same logger lifecycle operation recursively. Those paths could cause non-termination, unbounded route growth or inconsistent lifecycle progress.

The audit also found that context views had no construction-time field-count limit and observable sink counters used unchecked increments. These gaps conflict with Obsidian's bounded-resource and non-recursive failure requirements even though the ordinary tested paths were finite.

## Decision

- One logger owns at most 64 simultaneously registered sinks. The typed factory rejects a larger set before constructing any sink.
- Registration identifiers are monotonic and fail with a fixed category before they can exceed `2147483647`; identifiers are never reused.
- Route mutation and scalar reconfiguration are rejected while redaction, filtering, sink dispatch, flush or close callbacks are active.
- The existing re-entry guard covers `log`, `flush` and `close`. Re-entry increments a saturating recursion counter; the outer operation records the corresponding fixed failure category and continues to later sinks.
- Logger close still attempts every registered sink and becomes closed exactly once. A removed sink remains outside logger ownership and must be closed by the caller.
- Bound context snapshots accept at most 256 fields, matching the record section limit. Oversized enabled events are rejected before the clock is read or context collision work begins.
- Memory drop/flush and console/file/rotation write/rotation counters use the same saturating `2147483647` ceiling as diagnostics.

## Consequences

Callback code cannot extend the loop that is currently invoking it, recursively flush or close the logger, or replace policy during an event. Healthy later routes still run after a rejected callback operation. Fixed errors and diagnostics never include callback exception text, record data or configuration values.

The 64-route limit is an explicit resource contract, not a performance claim. Applications requiring more destinations must compose a separately reviewed sink outside the logger or use multiple explicitly owned loggers. This decision does not add shared-logger thread safety; simultaneous cross-thread mutation remains unsupported.
