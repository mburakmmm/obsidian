# Performance measurements

Status: Phase 10 benchmark foundation; no performance guarantee.

Obsidian performance claims require a recorded environment and exact workload. Run the current in-process suite with the pinned NOX 2.1 compiler:

```sh
bash scripts/run-benchmarks.sh llvm
bash scripts/run-benchmarks.sh qbe
```

The first output line identifies the OS, kernel, architecture, CPU, compiler, pinned NOX source, Obsidian commit, dirty state and backend. Following lines report fixed warm-up counts, seven-sample mean/min/max, population variance and operations per second. JSONL also reports encoded bytes per event. The same command then runs the INFO text console workload with stdout redirected to a temporary regular file, JSONL file/rotation workloads in a temporary owned directory, prebuilt empty/Logger process-startup probes and peak-RSS probes. It verifies exact record/rotation/drop/failure counts, bounded retention, silent successful child exits and secret-sentinel absence before printing summaries.

Compilation is excluded from every measurement. `logger_construct_close` is only in-process logger construction plus close with no sinks; the separately named process-startup workloads include child launch and exit. The disabled `nox.log` workload is comparable only to Obsidian's disabled DEBUG early-rejection workload; it is not a general library speed comparison.

Do not publish a result when `dirty=true`. Keep LLVM and QBE separate. Record hardware/OS/compiler SHA, complete command output and any background-load caveat. Shared CI runner timing is useful for smoke detection only and is not a stable benchmark baseline.

The regular CI matrix runs the harness on LLVM and QBE to detect compile/runtime regressions. Values printed by that step are explicitly non-baseline observations and are not copied into this report.

Deterministic hardening property corpora cover 208 fixed cases: 101 UTF-8/control, large-value, scalar-tag and malformed-configuration cases plus 107 rotation filename/path-confinement cases. A separate NOX-native corpus uses fixed seed `20261109` for 2,048 reproducible JSON/text encoding, scalar field, mixed-case redaction, valid/hostile path, archive and invalid-threshold cases. Failures report only the category, seed and case index; generated content and the synthetic sentinel are not printed. This is bounded seeded regression evidence, not coverage-guided or unbounded fuzzing. File lifecycle stress is available separately through `scripts/run-file-stress.sh <llvm|qbe> <smoke|full>`; a result is publishable only from `full` mode on a clean commit. Async queue metrics are not applicable because async dispatch is unsupported on the pinned toolchain. See ADR-0014 for benchmark methodology and `todo.md` for the remaining Phase 10 work.

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

## File and forced-rotation observation — 2026-11-07

This observation was measured from clean commit `394b6e3794a75a814c5113b3ed0e8886912d49e8` on the same Apple M4 environment. Output lived only in the runner's temporary consumer directory.

| Workload | Warm-up operations | Operations per sample | Output validation |
|---|---:|---:|---|
| INFO JSONL file append | 200 | 2,000 | 14,200 uniform records; 242 bytes/event; no sentinel |
| Forced size rotation | 20 | 100 | 720 rotations after one priming write; 246-byte limit; one active line; zero archives |

| Backend | Workload | Mean ns/op | Min | Max | Variance ns² | Derived ops/s |
|---|---|---:|---:|---:|---:|---:|
| LLVM | INFO JSONL file append | 9,285 | 8,500 | 12,000 | 1,346,939 | 107,700 |
| LLVM | Forced size rotation | 365,714 | 350,000 | 380,000 | 81,632,653 | 2,734 |
| QBE | INFO JSONL file append | 9,857 | 9,000 | 12,500 | 1,408,163 | 101,450 |
| QBE | Forced size rotation | 374,285 | 360,000 | 390,000 | 81,632,653 | 2,671 |

The append result includes logger dispatch, record cloning, redaction, JSONL formatting and an unbuffered operating-system write. The rotation result additionally includes close, rename, reopen, directory validation and zero-archive retention deletion. Neither result includes `fsync`; neither establishes disk-full, crash, cross-process or stable-storage behavior.

## Prebuilt process-startup observation — 2026-11-07

This observation was measured from clean commit `1bde748e0f5981c634fc05fd810558e387a5f727` on the same Apple M4 environment using Python 3.15.2. Each binary was compiled before timing, warmed with 10 launches, then measured in seven batches of 50 launches.

| Backend | Workload | Mean ns/launch | Min | Max | Variance ns² | Derived launches/s |
|---|---|---:|---:|---:|---:|---:|
| LLVM | Empty NOX process | 1,991,553 | 1,956,740 | 2,047,361 | 921,308,835 | 502 |
| LLVM | Logger construct/close process | 2,023,200 | 1,991,166 | 2,075,648 | 1,159,835,269 | 494 |
| QBE | Empty NOX process | 2,009,690 | 1,977,195 | 2,089,265 | 1,271,657,939 | 497 |
| QBE | Logger construct/close process | 2,095,360 | 2,069,418 | 2,138,836 | 482,081,099 | 477 |

The result includes host `subprocess.run`, operating-system process creation, loader/runtime initialization and process exit. Every child returned zero and produced empty stdout/stderr. Empty and Logger values are not subtracted: their difference is not an exact Logger cost because launch and scheduling noise can dominate it. The in-process `logger_construct_close` workload remains the direct construction measurement.

## Bounded and failing sink peak RSS — 2026-11-07

This observation was measured from clean commit `f66c6ad0ef0b18ef5edeba9903f59e048e2358ac` on the same Apple M4 environment using Python 3.15.2 and seven fresh processes per workload. Values are normalized peak resident bytes.

| Backend | Workload | Mean RSS bytes | Min | Max | Variance bytes² |
|---|---|---:|---:|---:|---:|
| LLVM | Empty runtime | 1,785,856 | 1,785,856 | 1,785,856 | 0 |
| LLVM | Bounded MemorySink | 2,389,723 | 2,375,680 | 2,392,064 | 32,869,647 |
| LLVM | Repeated failing sink | 2,260,992 | 2,260,992 | 2,260,992 | 0 |
| LLVM | Deterministic slow sink | 2,260,992 | 2,260,992 | 2,260,992 | 0 |
| QBE | Empty runtime | 1,832,667 | 1,818,624 | 1,835,008 | 32,869,647 |
| QBE | Bounded MemorySink | 3,080,192 | 3,080,192 | 3,080,192 | 0 |
| QBE | Repeated failing sink | 2,881,243 | 2,867,200 | 2,883,584 | 32,869,647 |
| QBE | Deterministic slow sink | 2,897,627 | 2,883,584 | 2,899,968 | 32,869,647 |

The bounded probe processed 50,000 events, retained exactly 128 snapshots and counted 49,872 dropped-oldest events. The failing probe performed and counted 50,000 sanitized write failures without retaining records. The slow probe performed 10,000 sanitized synchronous callbacks with 200 deterministic CPU-delay iterations and retained no records. Every probe report was identical across samples and no synthetic sentinel appeared.

Peak RSS includes the NOX runtime, allocator high-water behavior, probe code and bounded snapshot validation. The empty runtime is context, not a value to subtract into an exact Obsidian allocation. The slow fixture is not a disk/network latency model, and these short finite probes are not long-running leak evidence.

## Bounded file lifecycle stress observation — 2026-11-08

This observation was measured from clean commit `15fed48e7184b38c7bb3dcdef46ad16c1e784dee` on the same Apple M4 environment using Python 3.15.2. It is bounded repeated-process evidence, not a leak, durability or throughput guarantee.

Each backend ran three fresh processes. Per process, the append path wrote 40,000 records and the rotation path wrote another 40,000 records. Both sinks were flushed, closed idempotently and reconstructed every 1,000 writes. The host watchdog allowed 120 seconds per process and streamed validation over the resulting files.

| Backend | Completed rounds | Events/path total | Mean elapsed ms/round | Min | Max | Mean peak RSS bytes | Min | Max |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| LLVM | 3 | 120,000 | 2,057 | 1,999 | 2,160 | 3,304,106 | 3,293,184 | 3,325,952 |
| QBE | 3 | 120,000 | 2,073 | 2,042 | 2,132 | 3,522,560 | 3,522,560 | 3,522,560 |

Every round produced exactly 9,680,000 append bytes from 40,000 masked 242-byte JSONL records. The rotation path used 245-byte records and a 3,920-byte active/archive limit, completed exactly 2,499 rotations, retained four archives plus the active file, and remained at exactly 19,600 retained bytes. Archive sequences were contiguous across 40 reopen cycles per path and process. The first record of every retained file parsed with schema `obsidian.log.v1`; every remaining line was byte-identical, every denylisted field was `***`, no synthetic sentinel appeared, and no round timed out or exited unsuccessfully.

CI run `42471701337` separately passed one 8,000-event smoke round per path and backend on macOS arm64, Linux x64 and Linux arm64. Shared-runner timings and RSS are not copied into this observation.
