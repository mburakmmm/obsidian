# Performance measurements

Status: Phase 10 benchmark foundation; no performance guarantee.

Obsidian performance claims require a recorded environment and exact workload. Run the current in-process suite with the pinned NOX 2.1 compiler:

```sh
bash scripts/run-benchmarks.sh llvm
bash scripts/run-benchmarks.sh qbe
```

The first output line identifies the OS, kernel, architecture, CPU, compiler, pinned NOX source, Obsidian commit, dirty state and backend. Following lines report fixed warm-up counts, seven-sample mean/min/max, population variance and operations per second. JSONL also reports encoded bytes per event.

These measurements exclude compilation and process startup. `logger_construct_close` is only in-process logger construction plus close with no sinks. The disabled `nox.log` workload is comparable only to Obsidian's disabled DEBUG early-rejection workload; it is not a general library speed comparison.

Do not publish a result when `dirty=true`. Keep LLVM and QBE separate. Record hardware/OS/compiler SHA, complete command output and any background-load caveat. Shared CI runner timing is useful for smoke detection only and is not a stable benchmark baseline.

No console, file, rotation, memory, process-startup, long-message, fuzz or stress result has been published yet. Async queue metrics are not applicable because async dispatch is unsupported on the pinned toolchain. See ADR-0014 for methodology and `todo.md` for the remaining Phase 10 work.
