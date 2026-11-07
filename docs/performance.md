# Performance measurements

Status: Phase 10 benchmark foundation; no performance guarantee.

Obsidian performance claims require a recorded environment and exact workload. Run the current in-process suite with the pinned NOX 2.1 compiler:

```sh
bash scripts/run-benchmarks.sh llvm
bash scripts/run-benchmarks.sh qbe
```

The first output line identifies the OS, kernel, architecture, CPU, compiler, pinned NOX source, Obsidian commit, dirty state and backend. Following lines report fixed warm-up counts, seven-sample mean/min/max, population variance and operations per second. JSONL also reports encoded bytes per event. The same command then runs the INFO text console workload with stdout redirected to a temporary regular file and verifies the exact record count and secret-sentinel absence before printing its summary.

These measurements exclude compilation and process startup. `logger_construct_close` is only in-process logger construction plus close with no sinks. The disabled `nox.log` workload is comparable only to Obsidian's disabled DEBUG early-rejection workload; it is not a general library speed comparison.

Do not publish a result when `dirty=true`. Keep LLVM and QBE separate. Record hardware/OS/compiler SHA, complete command output and any background-load caveat. Shared CI runner timing is useful for smoke detection only and is not a stable benchmark baseline.

The regular CI matrix runs the harness on LLVM and QBE to detect compile/runtime regressions. Values printed by that step are explicitly non-baseline observations and are not copied into this report.

No file, rotation, memory, process-startup, fuzz or stress result has been published yet. Async queue metrics are not applicable because async dispatch is unsupported on the pinned toolchain. See ADR-0014 for methodology and `todo.md` for the remaining Phase 10 work.

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

## Redirected console and long Unicode observation — 2026-11-07

This extends the same machine-specific baseline policy. It was measured from clean commit `31abb7b9ce5bb7865fb3f7a4adabcf6e1bc6179a` with the hardware, OS, compiler and NOX source listed above.

| Workload | Warm-up operations | Operations per sample | Output validation |
|---|---:|---:|---|
| Maximum-length Unicode JSONL | 2 | 20 | 196,824 bytes/event |
| Redirected INFO text console | 200 | 2,000 | 14,200 records plus 2 report lines; no synthetic sentinel |

| Backend | Workload | Mean ns/op | Min | Max | Variance ns² | Derived ops/s | Bytes/event |
|---|---|---:|---:|---:|---:|---:|---:|
| LLVM | Maximum-length Unicode JSONL | 3,157,142 | 3,150,000 | 3,200,000 | 306,122,449 | 316 | 196,824 |
| LLVM | Redirected INFO text console | 9,000 | 8,000 | 11,000 | 857,142 | 111,111 | — |
| QBE | Maximum-length Unicode JSONL | 3,207,142 | 3,150,000 | 3,250,000 | 1,020,408,164 | 311 | 196,824 |
| QBE | Redirected INFO text console | 9,428 | 8,500 | 12,000 | 1,316,326 | 106,067 | — |

The console result includes the synchronous logger, record cloning, redaction, text formatting and writes to a redirected regular file. It is not a terminal, pipe, stderr or durability measurement. The Unicode workload uses `MAX_MESSAGE_LENGTH` code points and canonical JSONL encoding; it is not a claim about arbitrary message sizes.
