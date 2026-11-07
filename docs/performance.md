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

## Initial macOS arm64 observation — 2026-11-07

This is a machine-specific baseline, not a guarantee:

| Property | Value |
|---|---|
| Host | MacBook Air, Apple M4, arm64 |
| OS | macOS 27.2; Darwin 27.2.0 |
| Compiler | `noxc 2.1.0` |
| NOX source | `fd107b922c67a804520dc30f849039d977542f6c` |
| Obsidian source | `38349634c5bf8b0e3535da2a38770af36bd2bc4c` |
| Tree state | `dirty=false` |
| Samples | 7 per workload/backend |
| Run policy | LLVM and QBE executed sequentially; ordinary workstation services were not disabled |

Workload parameters:

| Workload | Warm-up operations | Operations per sample |
|---|---:|---:|
| Disabled DEBUG, Obsidian and `nox.log` | 100,000 | 2,000,000 |
| JSONL encoding | 200 | 2,000 |
| Logger construct + close | 1,000 | 20,000 |

Observed aggregate estimates:

| Backend | Workload | Mean ns/op | Min | Max | Variance ns² | Derived ops/s | Bytes/event |
|---|---|---:|---:|---:|---:|---:|---:|
| LLVM | Obsidian disabled DEBUG | 59 | 58 | 63 | 3 | 16,949,152 | — |
| LLVM | `nox.log` disabled DEBUG | 1 | 1 | 1 | 0 | 1,000,000,000 | — |
| LLVM | JSONL encoding | 6,214 | 6,000 | 6,500 | 61,224 | 160,926 | 309 |
| LLVM | Logger construct + close | 92 | 50 | 100 | 306 | 10,869,565 | — |
| QBE | Obsidian disabled DEBUG | 74 | 73 | 78 | 2 | 13,513,513 | — |
| QBE | `nox.log` disabled DEBUG | 1 | 1 | 2 | 0 | 1,000,000,000 | — |
| QBE | JSONL encoding | 7,000 | 7,000 | 7,000 | 0 | 142,857 | 309 |
| QBE | Logger construct + close | 135 | 100 | 150 | 510 | 7,407,407 | — |

The monotonic clock is read once per complete sample and has millisecond resolution. The `nox.log` mean reaches the integer nanosecond floor; its zero/near-zero variance and reciprocal throughput are quantized artifacts, not evidence of exact one-nanosecond calls. No ratio claim is made. Re-run the command on the target system before making capacity decisions.
