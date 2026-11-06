# NOX compatibility baseline

Status: Phase 0–6 supported synchronous scope passes pinned local LLVM/QBE verification and the supported CI matrix. The Phase 7 capability audit reaches a local no-go decision for async dispatch and awaits remote matrix evidence. This document does not extend support beyond tested jobs.

## Pinned toolchain

| Item | Pinned/observed value | Evidence |
|---|---|---|
| NOX source | `a8940d27826849a526c3e918126ac6dd6ef571d1` | Annotated upstream tag `v2.0.143` resolves to this commit |
| Pinned test compiler | `noxc 2.0.143` | Verified release archive, `noxc --version` on 2026-11-06 |
| Release archive SHA-256 | `fab24640892ef054bff50eeba901fa953d13424319729a9b095d3a31694589e4` | Published checksum plus local `shasum -a 256 -c` |
| Compiler binary SHA-256 | `4070e9d4582bb961395be2b2dbbb96eb3f5278f954adf38112c2c4baf9d51676` | Extracted pinned release binary |
| Ambient user compiler | `noxc 2.0.188` | Observed on 2026-11-06; not the support pin and not used for final Phase 4 evidence |
| Host | macOS 27.0.1, arm64 | `sw_vers`, `uname -m` |
| C compiler | Apple clang 21.0.0 | `clang --version` |
| Bundled QBE | present in the verified 2.0.143 release archive | filesystem inspection |
| Profile under test | `hosted` | filesystem, process and clock APIs are required |

The compiler reports a version but not its source SHA. The annotated `v2.0.143` tag resolves to the selected commit, but GitHub reports the tag as unsigned. Release assets include per-platform SHA-256 files; local verification and CI check the downloaded archive against the matching checksum before use. This is integrity evidence, not signed provenance. The ambient user installation has advanced to 2.0.188 and is deliberately not treated as the project support baseline.

## Audited public APIs at the pinned revision

| Area | Observed public contract | Obsidian consequence | Status |
|---|---|---|---|
| `nox.log` | `format`, `redact`, `mask_assignments`, module-level threshold, stdout-only `debug/info/warn/error` | Wrap and extend; never change stdlib state implicitly | Phase 1 compile/behavior probes pass on LLVM/QBE |
| `nox.regex` / strings | bounded regex search/replace, escaping, Unicode string methods | Use fixed/escaped patterns; bypass matcher when no sensitive marker so arbitrary controls retain formatter semantics | Phase 4 header/Bearer/URL/query/control probes pass locally and in supported CI jobs |
| `nox.json` | `JsonValue`, typed accessors, `dump_string`, `JsonWriter` | Use writer/escaping; test writer nesting because it does not validate structure | Phase 2 JSONL/golden/typed round-trip probes pass on LLVM/QBE |
| `nox.fs` | synchronous `open_append`; unbuffered `write`; explicit/idempotent `close`; metadata size; rename/create/read/remove operations | File sinks close explicitly; size rotation uses byte metadata; `flush` is not `fsync` | Phase 6 size/rename/retention/restart probes pass locally and in supported CI on LLVM/QBE |
| `nox.path` | `canonicalize`, `join`, `strip_prefix`, components | Constrain file/retention paths against a canonical allowed root | Phase 3 traversal/prefix/existing-symlink probes pass on supported CI jobs and local LLVM/QBE |
| built-in `print` / `nox.console` | stdout only; no `file=` target, stdio flush or recoverable write-error channel | Support explicit stdout; reject stderr; document logical flush | Stdout exact-capture probe passes on supported CI jobs and locally; stderr blocked |
| `nox.os` | `getenv` raises `OsError` when absent; `current_dir`, `set_var` | Environment overrides require explicit `try/except OsError` | Phase 5 missing/valid/invalid env probes pass locally and in supported CI on LLVM/QBE |
| `nox.time` | UTC `DateTime`; wall `now_ms`; monotonic `Instant`; `boot_ms` | Inject wall clock for records and monotonic clock for timeouts/durations | Fake clock and epoch-to-RFC3339 probes pass on LLVM/QBE |
| `nox.thread` | awaited blocking `ThreadChannel.send/recv`; join-only `ThreadHandle`; QBE scalar element restriction | No portable record queue, non-blocking overflow or timeout-aware shutdown contract | Phase 7 executable probes pass locally; async no-go |
| `nox.atomic` | process-wide scalar cells; explicit handle reconstruction and one manual `free` after worker completion | Never free before a proven join; atomics cannot hold a record graph | Phase 7 overlap/lifetime probe passes locally on LLVM and QBE |
| scheduler | LLVM M:N work-stealing; QBE cooperative tasks plus separate runtimes for `nox.thread.start`; channel waits ignore task cancellation | Backend-specific evidence is mandatory and does not imply portable queue semantics | LLVM real-worker peak is 2 locally; QBE scalar thread-channel probe passes |
| modules | project-root files; cyclic imports rejected; dependency aliases expose package modules; package self-imports use the manifest name | Root `.nox` modules plus `obsidian.*` self-imports; test through a consumer project | Full transitive downstream package graph passes on LLVM/QBE |
| tests | every `*_test.nox` is a program; failures raise/exit non-zero; `nox.test` has typed assertions and `TestSuite` | Count cases/assertions explicitly; capability and compile-fail probes remain separate from behavioral totals | Phase 7 local: 14 files/325 assertions/0 skips pass on LLVM/QBE; six async capability probes and three negative fixtures pass separately |

## Known gaps and conservative decisions

| Capability | Finding at baseline | Decision |
|---|---|---|
| File `fsync`/durable flush | No documented public API | Do not claim stable-storage durability; `flush` semantics remain logical/sink-specific |
| TTY detection | No documented public API found in the mandatory audit | Default to no ANSI; color remains disabled until a public capability is proven |
| Stack trace/source inspection | No documented public API proven | Do not implement `logger.exception` or source capture yet |
| Seeded random sampling | No documented public API proven | Defer sampling or implement a deterministic pure hash only after ADR/tests |
| Temporary test directory helper | No `nox.test` helper documented | Use explicitly scoped fixtures and cleanup; do not invent a helper |
| Recursive structures | JSON supports nested trees, but Obsidian's typed field model is undecided | Resolve in ADR-0002 and compile tests before implementation |
| Immutable classes | NOX class fields are mutable and visibility is conventional | Deep-copy caller data, expose clone-returning accessors and keep internal storage underscore-prefixed; do not claim language-enforced immutability |
| Cross-process file rotation | No lock/atomic rotation contract proven | Size rotation is single-process only; cross-process ownership remains unsupported |
| Time-based rotation | Wall and metadata clocks exist, but rollback/restart boundary semantics are not yet specified or injected | Keep disabled; Phase 6 ships size-based rotation only |
| Async multi-producer safety | QBE rejects class-valued thread channels; no `try_send`/`try_recv`, channel close, thread cancellation or timed join; sync send fails codegen | Phase 7 no-go: keep async API and `QueueConfig` absent; re-evaluate only under ADR-0011 triggers |
| Shared synchronous logger concurrency | Phase 5 proves overlapping task-local explicit context snapshots, not simultaneous mutation/dispatch through one logger instance | Make no shared-logger thread-safety claim; explicit context isolation is not an async dispatcher guarantee |
| Native glue | Stderr/no-follow gaps exist, but a portable boundary has not been designed or approved | Keep unsupported paths disabled; no Zig/NNI code without a separate ADR |
| `Logger.trace` spelling | NOX 2.0.143 type-checks it but LLVM codegen emits a duplicate `logger_Logger_trace` symbol in the current module graph | Keep the common `log(TRACE, ...)` path and temporary `trace_event` convenience method; retest on compiler upgrade before stabilizing the API |
| Maximum finite float literal in `noxc fmt` | Formatting a source literal at IEEE-754 maximum returned `NoSpaceLeft`; parsing the exact decimal with documented `float(str)` preserves the value and formats cleanly | Keep the compile/runtime regression and avoid the problematic literal spelling at this compiler revision |
| Root-project package self-name | 2.0.143 and 2.0.181 resolve `obsidian.*` correctly inside an installed dependency, but not while Obsidian itself is the root project | Use manifest-name self-imports and run tests/examples through the isolated downstream harness in ADR-0006 |
| Stderr and console flush | No public API in 2.0.143 or observed 2.0.181 docs; `print(file=...)` is explicitly unsupported | Keep stderr disabled with `SinkError`; console flush is logical only; no native shim without a separate ADR |
| Race-free no-follow file open | No `lstat`, `openat`, `O_NOFOLLOW` or equivalent public API | Require trusted allowed root; reject lexical and existing symlink escapes; do not claim hostile-directory race safety |
| Streaming directory iteration | `nox.fs.read_dir` returns the complete name list | Rotation caps processing at 10,000 entries and requires a dedicated trusted log directory; initial stdlib list allocation cannot be bounded internally |
| `nox.path.strip_prefix` component boundary | Pinned 2.0.143 treats `/safe/root2` as prefixed by `/safe/root`; observed 2.0.181 does not | Do not use it for confinement; compare canonical path components exactly and retain the regression test |

## Backend and platform matrix

| Platform/backend | Check | Build/run | Tests | Concurrency claim |
|---|---:|---:|---:|---|
| macOS arm64 / LLVM | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` attempt 2 | Overlapping explicit context tasks pass; no shared-logger claim |
| macOS arm64 / QBE | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` attempt 2 | Cooperative overlapping context tasks pass; no OS-thread claim |
| Linux x64 / LLVM | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` | Overlapping explicit context tasks pass; no shared-logger claim |
| Linux x64 / QBE | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` | Cooperative overlapping context tasks pass; no OS-thread claim |
| Linux arm64 / LLVM | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` | Overlapping explicit context tasks pass; no shared-logger claim |
| Linux arm64 / QBE | Pass | Pass | Phase 6: 14 files, 325 assertions, 0 skips; CI run `42250864512` | Cooperative overlapping context tasks pass; no OS-thread claim |
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

All source paths above refer to commit `a8940d27826849a526c3e918126ac6dd6ef571d1` in `mburakmmm/nox-lang`.
