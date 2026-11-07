# ADR-0014: reproducible benchmark methodology

- Status: accepted for the Phase 10 benchmark foundation
- Date: 2026-11-07

## Context

Phase 10 requires measurements without turning a single developer-machine result into a portability or performance guarantee. NOX exposes a monotonic `Instant` with millisecond resolution. Compilation time, process startup, sink I/O and in-process operations are different workloads and must not be mixed into one number.

## Decision

`benchmarks/core_bench.nox` measures only steady-state in-process operations. The clock starts after the downstream package has compiled and the program has started. Every workload has a fixed warm-up, iteration count and seven samples. Reports include mean/min/max nanoseconds per operation and population variance in squared nanoseconds. Nanoseconds are derived from monotonic elapsed milliseconds over many operations; they are aggregate estimates, not per-call timer readings.

The benchmark runner always records OS, kernel, architecture, CPU description when available, `noxc --version`, exact pinned NOX source SHA, Obsidian commit, dirty state and backend. A publishable result must use `dirty=false`. LLVM and QBE results are separate and must not be averaged together.

The first workload set is:

1. Obsidian disabled `Logger.debug` with an INFO threshold.
2. `nox.log.debug` disabled by the equivalent INFO threshold, as the only comparison baseline in this slice.
3. Canonical JSONL encoding of one fixed typed Unicode record, including bytes per event.
4. Logger construction plus idempotent close with no sinks, explicitly not process startup.

The disabled DEBUG comparison uses the same fixed message and measures early-rejection calls only. It does not compare stdout, file or formatter work. The JSON workload consumes the returned byte length to prevent an unused-result benchmark. Logger construction verifies close state on every iteration. Synthetic secret input is present in the JSON fixture, and the runner rejects any benchmark output containing the sentinel.

Console/file/rotation throughput, process startup, long-message fixtures, memory profiling and stress/fuzz workloads remain separate because they need different isolation and evidence. Async enqueue metrics remain not applicable while ADR-0011 keeps async disabled.

## Consequences

- Results are reproducible from `scripts/run-benchmarks.sh <llvm|qbe>` but remain machine-specific observations.
- A result from a dirty tree, different compiler SHA or different workload parameters cannot be compared as the same baseline.
- Millisecond aggregate timing limits fine-grained precision; the runner fails when a workload is too short for even one millisecond.
- CI may compile or smoke-run benchmarks, but noisy shared-runner numbers are not release performance evidence.
