# ADR-0014: reproducible benchmark methodology

- Status: accepted for the Phase 10 benchmark foundation
- Date: 2026-11-07

## Context

Phase 10 requires measurements without turning a single developer-machine result into a portability or performance guarantee. NOX exposes a monotonic `Instant` with millisecond resolution. Compilation time, process startup, sink I/O and in-process operations are different workloads and must not be mixed into one number.

## Decision

`benchmarks/core_bench.nox` measures steady-state in-process operations. `benchmarks/console_bench.nox` separately measures the complete synchronous INFO path through redaction, text formatting and a stdout console sink while the runner redirects stdout to a regular file. `benchmarks/file_bench.nox` measures the corresponding JSONL append path and a forced size-rotation path inside the runner's temporary consumer directory. The clock starts after the downstream package has compiled and the program has started. Every workload has a fixed warm-up, iteration count and seven samples. Reports include mean/min/max nanoseconds per operation and population variance in squared nanoseconds. Nanoseconds are derived from monotonic elapsed milliseconds over many operations; they are aggregate estimates, not per-call timer readings.

Process startup is a separate host-driven workload. The runner first builds `process_empty.nox` and `process_logger.nox` for the selected backend, then a long-lived Python 3 standard-library harness uses `time.monotonic_ns()` around `subprocess.run()` calls. Compilation is therefore excluded and a timer process is not launched inside each measurement. Python is a development benchmark prerequisite only; it is not an Obsidian package or runtime dependency.

The benchmark runner always records OS, kernel, architecture, CPU description when available, `noxc --version`, exact pinned NOX source SHA, Obsidian commit, dirty state and backend. A publishable result must use `dirty=false`. LLVM and QBE results are separate and must not be averaged together.

The first workload set is:

1. Obsidian disabled `Logger.debug` with an INFO threshold.
2. `nox.log.debug` disabled by the equivalent INFO threshold, as the only comparison baseline in this slice.
3. Canonical JSONL encoding of one fixed typed Unicode record, including bytes per event.
4. Logger construction plus idempotent close with no sinks, explicitly not process startup.
5. Canonical JSONL encoding of a maximum-length Unicode message.
6. INFO text logging through the synchronous logger and redirected stdout console sink.
7. INFO JSONL logging through the synchronous logger and unbuffered append-only file sink.
8. INFO JSONL logging where every measured write forces size rotation, reopen and zero-archive retention.
9. Prebuilt empty NOX process startup and exit.
10. Prebuilt NOX process startup, one explicit Logger construction and idempotent close, then exit.

The disabled DEBUG comparison uses the same fixed message and measures early-rejection calls only. It does not compare stdout, file or formatter work. JSON workloads consume the returned byte length to prevent unused-result benchmarks. The pathological Unicode fixture uses the supported maximum 65,536-code-point message and records its encoded bytes per event. Logger construction verifies close state on every iteration.

The redirected console workload writes 200 warm-up events and seven samples of 2,000 events. Its fixture includes a denylisted synthetic secret. The runner requires exactly 14,202 output lines: 14,200 records plus the schema and result lines. It rejects a missing report, a line-count mismatch or any unmasked `SYNTHETIC_` sentinel. This measurement includes stdout writes to the redirected file but does not claim terminal, pipe, stderr or durability performance.

The file workload writes 200 warm-up events and seven samples of 2,000 events, then requires exactly 14,200 newline-terminated, uniform-size outputs and reports bytes per event. The rotation workload primes one active record, performs 20 warm-up rotations and seven samples of 100 rotations. Its byte limit equals the encoded fixture size and `max_archives=0`, so every timed write must rotate and retention must leave one active line with no archive. Both paths use a denylisted synthetic secret; the runner requires the masked marker and rejects the original sentinel anywhere under the temporary benchmark output root.

The file timing includes the complete logger/redaction/JSONL path and an unbuffered operating-system append. It does not include `fsync` because NOX exposes no such public API. The rotation timing includes formatting, close, rename, reopen, directory validation and deletion; it is not an isolated rename syscall measurement and does not establish crash, cross-process or durable-write guarantees.

Each startup workload has 10 warm-up launches and seven samples of 50 launches. The harness requires zero exit status and empty stdout/stderr for every child. It records the Python version because host process-launch behavior is part of the observation. Empty and Logger startup results remain separate; subtracting them is not presented as an exact Logger construction cost because scheduler, dynamic-loader and process-launch noise can dominate the difference. The in-process construction workload remains the direct Logger construction measurement.

Memory profiling and stress/fuzz workloads remain separate because they need different isolation and evidence. Async enqueue metrics remain not applicable while ADR-0011 keeps async disabled.

## Consequences

- Results are reproducible from `scripts/run-benchmarks.sh <llvm|qbe>` but remain machine-specific observations.
- A result from a dirty tree, different compiler SHA or different workload parameters cannot be compared as the same baseline.
- Millisecond aggregate timing limits fine-grained precision; the runner fails when a workload is too short for even one millisecond.
- CI may compile or smoke-run benchmarks, but noisy shared-runner numbers are not release performance evidence.
