# ADR-0023 — MemorySink ring storage

The saturated memory sink now replaces the oldest slot in place. Before saturation, the list grows with retained events. This preserves lazy allocation for large configured capacities and avoids shifting retained records on every saturated write.

Clone each input before modifying storage or counters. Keep the oldest physical slot private and translate logical FIFO reads to physical slots. Out-of-range reads still follow the native list error path, and valid negative indices count from the newest end. Snapshots and indexed reads return clones. Close keeps retained records accessible while rejecting writes and flushes.

This changes only synchronous internal storage. The existing dispatcher ownership and external serialization rules apply. The [prototype comparison](../performance.md#nox-2238-clean-baseline-and-memorysink-prototype) motivates the change, and the benchmark now measures the public production sink at the same three capacities.
