# NOX compatibility baseline

Status: Phase 0–9 evidence is green on NOX 2.1.0. The Phase 10 benchmark harness and deterministic hardening property corpora pass on the supported remote matrix. The seeded fuzz corpus passes locally on LLVM/QBE; its remote matrix is pending. This document does not extend support beyond tested jobs.

## Pinned toolchain

| Item | Pinned/observed value | Evidence |
|---|---|---|
| NOX source | `fd107b922c67a804520dc30f849039d977542f6c` | Annotated upstream tag `v2.1.0` resolves to this commit |
| Pinned test compiler | `noxc 2.1.0` | Verified release archive, `noxc --version` on 2026-11-07 |
| Release archive SHA-256 | `b96d286772da8eaa9d161824d7e4c91c34af85874045dbbae44909b607e65062` | Published checksum plus local `shasum -a 256 -c` |
| Compiler binary SHA-256 | `41296804cf1fe802e778f26940265dd1451dee5cdaf4838e7cc66c3329e49eb0` | Extracted pinned release binary |
| Ambient user compiler | `noxc 2.1.0` | Observed on 2026-11-07; final evidence uses the isolated verified archive |
| Host | macOS 27.2, arm64 | `sw_vers`, `uname -m` |
| C compiler | Apple clang 21.0.0 | `clang --version` |
| Bundled QBE | present in the verified 2.1.0 release archive | filesystem inspection |
| Profile under test | `hosted` | filesystem, process and clock APIs are required |

The compiler reports a version but not its source SHA. The annotated `v2.1.0` tag resolves to the selected commit and contains no signature. Release assets include per-platform SHA-256 files; local verification and CI run `42308138269` checked the platform archives against their matching checksums on macOS arm64 and Linux x64/arm64. This is integrity evidence, not signed provenance. The ambient installation matches the pin, but the isolated checksum-verified archive remains the evidence source.

CI run `42363929287` additionally passed the complete Phase 9 behavioral/integration matrix and the Phase 10 LLVM/QBE benchmark smoke step on macOS arm64, Linux x64 and Linux arm64. Shared-runner timings are deliberately not treated as performance baselines.

CI run `42395481106` passed the Phase 10 deterministic property addition on the same matrix: 18 behavioral files/396 assertions/0 skips per backend, 101 bounded corpus cases, three expected compile-fail fixtures, and the existing capability, adapter and benchmark-smoke checks.

CI run `42398683809` passed the rotation/path hardening addition on macOS arm64, Linux x64 and Linux arm64 with LLVM/QBE: 19 behavioral files/407 assertions/0 skips, 207 total deterministic property cases, three expected compile-fail fixtures, and the existing capability, adapter and benchmark-smoke checks.

CI run `42470080183` revalidated the same matrix after direct GitHub release URLs repeatedly returned HTTP 504 before tests could start. Pinned toolchain acquisition now uses the authenticated GitHub Release API with three bounded attempts, removes partial named assets before retrying, and still verifies the release-provided SHA-256 before extraction. This improves CI transport reliability without changing the compiler pin or provenance claim.

CI run `42471701337` added bounded file/rotation lifecycle smoke coverage on macOS arm64, Linux x64 and Linux arm64. Each job passed LLVM and QBE 8,000-event append and 8,000-event rotation rounds with timeout, exact JSONL/byte/retention checks and sentinel scanning, in addition to the existing 19 behavioral files/407 assertions/0 skips, capability probes, adapters and benchmark smoke.

Local NOX 2.1.0 LLVM/QBE verification on 2026-11-09 added 2,048 fixed-seed fuzz cases and a sensitive-directory regression, for 20 behavioral files/414 assertions/0 skips and 208 fixed property cases. Remote platform evidence is pending and is not inferred from the local run.

## Audited public APIs at the pinned revision

| Area | Observed public contract | Obsidian consequence | Status |
|---|---|---|---|
| `nox.log` | `format`, `redact`, `mask_assignments`, module-level threshold, stdout-only `debug/info/warn/error` | Wrap and extend; never change stdlib state implicitly | Phase 1 compile/behavior probes pass on LLVM/QBE |
| `nox.regex` / strings | bounded regex search/replace, escaping, Unicode string methods | Use fixed/escaped patterns; bypass matcher when no sensitive marker so arbitrary controls retain formatter semantics | Phase 4 header/Bearer/URL/query/control probes pass locally and in supported CI jobs |
| `nox.json` | `JsonValue`, typed accessors, `dump_string`, `JsonWriter` | Use writer/escaping; test writer nesting because it does not validate structure | Phase 2 JSONL/golden/typed round-trip probes pass on LLVM/QBE |
| `nox.fs` | synchronous `open_append`; unbuffered `write`; explicit/idempotent `close`; metadata size; rename/create/read/remove operations | File sinks close explicitly; size rotation uses byte metadata; `flush` is not `fsync` | Phase 6 size/rename/retention/restart probes pass locally and in supported CI on LLVM/QBE |
| `nox.path` | `canonicalize`, `join`, `strip_prefix`, components | Constrain file/retention paths against a canonical allowed root; reject raw controls before native path calls | Phase 10 CI `42398683809`: 106 deterministic rotation/path cases; local seeded-fuzz verification adds the sensitive-directory boundary regression |
| built-in `print` / `nox.console` | stdout only; no `file=` target, stdio flush or recoverable write-error channel | Support explicit stdout; reject stderr; document logical flush | Stdout exact-capture probe passes on supported CI jobs and locally; stderr blocked |
| `nox.os` | `getenv` raises `OsError` when absent; `current_dir`, `set_var` | Environment overrides require explicit `try/except OsError` | Phase 5 missing/valid/invalid env probes pass locally and in supported CI on LLVM/QBE |
| `nox.time` | UTC `DateTime`; wall `now_ms`; monotonic `Instant`; `boot_ms` | Inject wall clock for records and monotonic clock for timeouts/durations | Fake clock and epoch-to-RFC3339 probes pass on LLVM/QBE |
| `nox.thread` | awaited blocking `ThreadChannel.send/recv`; join-only `ThreadHandle`; QBE scalar element restriction | No portable record queue, non-blocking overflow or timeout-aware shutdown contract | Phase 7 executable probes pass locally and in supported CI; async no-go |
| `nox.atomic` | process-wide scalar cells; explicit handle reconstruction and one manual `free` after worker completion | Never free before a proven join; atomics cannot hold a record graph | Phase 7 scalar/lifetime probes pass locally and in supported CI on LLVM/QBE; LLVM overlap observation is reported separately |
| scheduler | LLVM M:N work-stealing; QBE cooperative tasks; `Task.cancel` is cooperative, while `ThreadHandle` has join only and channels expose no close/timeout contract | Backend-specific evidence is mandatory and does not imply portable queue semantics | LLVM real-worker peak 2 is proven but scheduling-sensitive; QBE scalar thread-channel probe passes locally and in supported CI |
| modules | project-root files; cyclic imports rejected; dependency aliases expose package modules; package self-imports use the manifest name | Root `.nox` modules plus `obsidian.*` self-imports; test through a consumer project | Full transitive downstream package graph passes on LLVM/QBE |
| tests | every `*_test.nox` is a program; failures raise/exit non-zero; `nox.test` has typed assertions and `TestSuite` | Count cases/assertions explicitly; capability and compile-fail probes remain separate from behavioral totals | Local Phase 10: 20 files/414 assertions/0 skips, 208 fixed property cases and 2,048 seeded fuzz cases; remote evidence remains at CI `42398683809` until the new commit runs |

## Known gaps and conservative decisions

| Capability | Finding at baseline | Decision |
|---|---|---|
| File `fsync`/durable flush | No documented public API | Do not claim stable-storage durability; `flush` semantics remain logical/sink-specific |
| TTY detection | No documented public API found in the mandatory audit | Default to no ANSI; color remains disabled until a public capability is proven |
| Stack trace/source inspection | No documented public API proven | Do not implement `logger.exception` or source capture yet |
| Seeded random sampling | No documented public API proven | Defer sampling or implement a deterministic pure hash only after ADR/tests |
| Optimized route-config representation | Widened, nested and scalar-snapshot route config experiments produced invalid values or `SIGSEGV` under the pinned `noxc test` runner while direct debug execution could pass | Preserve `SinkConfig`; expose only proven programmatic routing and defer typed factory routes until a newer pinned compiler/representation passes LLVM/QBE tests |
| Temporary test directory helper | No `nox.test` helper documented | Use explicitly scoped fixtures and cleanup; do not invent a helper |
| Exception-heavy property aggregation | NOX 2.1.0 LLVM produced an invalid integer return when one helper both owned a large hostile-path corpus and caught every validation exception | Keep corpora at test-program scope and use small boolean helpers; this is a test-shape constraint, not production behavior evidence |
| Recursive structures | JSON supports nested trees, but Obsidian's typed field model is undecided | Resolve in ADR-0002 and compile tests before implementation |
| Immutable classes | NOX class fields are mutable and visibility is conventional | Deep-copy caller data, expose clone-returning accessors and keep internal storage underscore-prefixed; do not claim language-enforced immutability |
| Cross-process file rotation | No lock/atomic rotation contract proven | Size rotation is single-process only; cross-process ownership remains unsupported |
| Time-based rotation | Wall and metadata clocks exist, but rollback/restart boundary semantics are not yet specified or injected | Keep disabled; Phase 6 ships size-based rotation only |
| Async multi-producer safety | QBE rejects class-valued thread channels; no `try_send`/`try_recv`, channel close, thread cancellation or timed join; sync send fails codegen | Phase 7 no-go: keep async API and `QueueConfig` absent; re-evaluate only under ADR-0011 triggers |
| Shared synchronous logger concurrency | Phase 5 proves overlapping task-local explicit context snapshots, not simultaneous mutation/dispatch through one logger instance | Make no shared-logger thread-safety claim; explicit context isolation is not an async dispatcher guarantee |
| Native glue | Stderr/no-follow gaps exist, but a portable boundary has not been designed or approved | Keep unsupported paths disabled; no Zig/NNI code without a separate ADR |
| `Logger.trace` spelling | NOX 2.1.0 still type-checks it but LLVM codegen emits a duplicate `obsidian_logger_Logger_trace` symbol in an isolated downstream probe | Keep the common `log(TRACE, ...)` path and temporary `trace_event` convenience method |
| Maximum finite float literal in `noxc fmt` | Formatting a source literal at IEEE-754 maximum returned `NoSpaceLeft`; parsing the exact decimal with documented `float(str)` preserves the value and formats cleanly | Keep the compile/runtime regression and avoid the problematic literal spelling at this compiler revision |
| Root-project package self-name | 2.1.0 resolves `obsidian.*` correctly inside an installed dependency, but a direct root-project `noxc check logger.nox` still rejects the self-name | Use manifest-name self-imports and run tests/examples through the isolated downstream harness in ADR-0006 |
| Optional ecosystem modules | Unimported package modules may reference dependencies absent from the core consumer; imported modules resolve through the consumer's aliases | Keep Nyx/Aether/Quartz outside `nox.json`; isolated probes pass at Nyx `v0.24.0`/`b4ef854…`, Aether `v0.9.0`/`d283a3b…` and Quartz `v0.9.15`/`a8e0b9b…` on local LLVM/QBE |
| Stderr and console flush | No public API in the 2.1.0 `nox.log`, `nox.console` or built-in docs; `print(file=...)` is explicitly unsupported | Keep stderr disabled with `SinkError`; console flush is logical only; no native shim without a separate ADR |
| Race-free no-follow file open | No `lstat`, `openat`, `O_NOFOLLOW` or equivalent public API | Require trusted allowed root; reject lexical and existing symlink escapes; do not claim hostile-directory race safety |
| Streaming directory iteration | `nox.fs.read_dir` returns the complete name list | Rotation caps processing at 10,000 entries and requires a dedicated trusted log directory; initial stdlib list allocation cannot be bounded internally |
| `nox.path.strip_prefix` component boundary | The historical 2.0.143 sibling-prefix defect is fixed by the current pin; existing component-wise confinement tests still pass | Retain explicit canonical component comparison and the regression test rather than changing security logic during the pin upgrade |

## Backend and platform matrix

| Platform/backend | Check | Build/run | Tests | Concurrency claim |
|---|---:|---:|---:|---|
| macOS arm64 / LLVM | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| macOS arm64 / QBE | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
| Linux x64 / LLVM | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| Linux x64 / QBE | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
| Linux arm64 / LLVM | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| Linux arm64 / QBE | Pass | Pass | Phase 10: 19 files/407 assertions/0 skips, 207 property cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42398683809` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
| Windows x64 | Not run | Not run | Not run | Unsupported until evidence exists |

## Upgrade policy

1. Change the pinned SHA and compiler version together.
2. Re-read every mandatory document at the new SHA.
3. Run import, unit, negative, security and both-backend tests.
4. Record behavior changes here and in `CHANGELOG.md`.
5. Do not update a released immutable tag in place.

## Primary pinned sources

- `docs/stdlib/log.md`, `json.md`, `fs.md`, `os.md`, `time.md`, `thread.md`, `atomic.md`
- `docs/stdlib/path.md`, `console.md`, `test.md`, `regex.md`, `strings.md`
- `docs/language/builtins.md`, `ffi.md`
- `docs/language/concurrency.md`, `modules.md`
- `docs/internals/architecture.md`
- `docs/tools/packages.md`, `testing.md`, `noxc.md`

All source paths above refer to commit `fd107b922c67a804520dc30f849039d977542f6c` in `mburakmmm/nox-lang`.
