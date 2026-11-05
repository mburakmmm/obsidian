# NOX compatibility baseline

Status: Phase 0 audit in progress. This document records observed capability; it is not a support claim for untested platforms.

## Pinned toolchain

| Item | Pinned/observed value | Evidence |
|---|---|---|
| NOX source | `a8940d27826849a526c3e918126ac6dd6ef571d1` | Annotated upstream tag `v2.0.143` resolves to this commit |
| Installed compiler | `noxc 2.0.143` | `noxc --version` on 2026-11-05 |
| Compiler binary SHA-256 | `4070e9d4582bb961395be2b2dbbb96eb3f5278f954adf38112c2c4baf9d51676` | `shasum -a 256 ~/.nox-lang/bin/noxc` |
| Host | macOS 27.0.1, arm64 | `sw_vers`, `uname -m` |
| C compiler | Apple clang 21.0.0 | `clang --version` |
| Bundled QBE | present at `~/.nox-lang/bin/qbe` | filesystem inspection |
| Profile under test | `hosted` | filesystem, process and clock APIs are required |

The installed binary reports a version but not its source SHA. The annotated `v2.0.143` tag resolves to the selected commit, but GitHub reports the tag as unsigned. Release assets include per-platform SHA-256 files; CI verifies the downloaded archive against the matching checksum before use. This is integrity evidence, not signed provenance.

## Audited public APIs at the pinned revision

| Area | Observed public contract | Obsidian consequence | Status |
|---|---|---|---|
| `nox.log` | `format`, `redact`, `mask_assignments`, module-level threshold, stdout-only `debug/info/warn/error` | Wrap and extend; never change stdlib state implicitly | Documented; compile probe pending |
| `nox.json` | `JsonValue`, typed accessors, `dump_string`, `JsonWriter` | Use writer/escaping; test writer nesting because it does not validate structure | Documented; compile probe pending |
| `nox.fs` | synchronous `open_append`; unbuffered `write`; explicit/idempotent `close`; metadata size; rename/create/read operations | File sink must close explicitly; `flush` cannot be advertised as `fsync` | Documented; integration probe pending |
| `nox.path` | `canonicalize`, `join`, `strip_prefix`, components | Constrain file/retention paths against a canonical allowed root | Documented; security probe pending |
| `nox.os` | `getenv` raises `OsError` when absent; `current_dir`, `set_var` | Environment overrides require explicit `try/except OsError` | Documented; compile probe pending |
| `nox.time` | UTC `DateTime`; wall `now_ms`; monotonic `Instant`; `boot_ms` | Inject wall clock for records and monotonic clock for timeouts/durations | Documented; fake-clock design pending |
| `nox.thread` | joinable async entry, bounded `ThreadChannel`; QBE argument restrictions | Async is conditional; never infer portable sharing from LLVM | Documented; Phase 7 deferred |
| `nox.atomic` | explicit allocation/`free`, handles for worker sharing | Worker ownership and join must precede free | Documented; Phase 7 deferred |
| scheduler | LLVM M:N work-stealing; QBE single-threaded cooperative | Backend-specific concurrency evidence is mandatory | Documented; Phase 7 deferred |
| modules | project-root modules; cyclic imports rejected; dependency alias prefixes package modules | Root `.nox` modules replace the proposed Python-style package layout | Local first-party and downstream alias probes pass on LLVM/QBE |
| tests | every `*_test.nox` is a program; failures raise/exit non-zero; `nox.test` has typed assertions and `TestSuite` | Count cases/assertions explicitly; compile-fail fixtures must not match `*_test.nox` | One file/two assertions pass on LLVM/QBE; negative fixture exits 1 |

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
| Cross-process file rotation | No lock/atomic rotation contract proven | Single-process ownership only; rotation deferred to Phase 6 |
| Async multi-producer safety | Primitives exist but record transport/lifetime is unproven, especially on QBE | Async disabled until Phase 7 go/no-go evidence |
| Native glue | No core capability gap yet | No Zig/NNI code permitted without a new ADR |
| `Logger.trace` spelling | NOX 2.0.143 type-checks it but LLVM codegen emits a duplicate `logger_Logger_trace` symbol in the current module graph | Keep the common `log(TRACE, ...)` path and temporary `trace_event` convenience method; retest on compiler upgrade before stabilizing the API |

## Backend and platform matrix

| Platform/backend | Check | Build/run | Tests | Concurrency claim |
|---|---:|---:|---:|---|
| macOS arm64 / LLVM | Pass | Pass | 1 file, 2 assertions, 0 skips | No concurrency claim |
| macOS arm64 / QBE | Pass | Pass | 1 file, 2 assertions, 0 skips | Cooperative behavior documented; no concurrency test yet |
| Linux x64 / LLVM | CI pending | CI pending | CI pending | None |
| Linux x64 / QBE | CI pending | CI pending | CI pending | None |
| Linux arm64 / LLVM | CI pending | CI pending | CI pending | None |
| Linux arm64 / QBE | CI pending | CI pending | CI pending | None |
| Windows x64 | Not run | Not run | Not run | Unsupported until evidence exists |

## Upgrade policy

1. Change the pinned SHA and compiler version together.
2. Re-read every mandatory document at the new SHA.
3. Run import, unit, negative, security and both-backend tests.
4. Record behavior changes here and in `CHANGELOG.md`.
5. Do not update a released immutable tag in place.

## Primary pinned sources

- `docs/stdlib/log.md`, `json.md`, `fs.md`, `os.md`, `time.md`, `thread.md`, `atomic.md`
- `docs/stdlib/path.md`, `test.md`
- `docs/language/concurrency.md`, `modules.md`
- `docs/internals/architecture.md`
- `docs/tools/packages.md`, `testing.md`, `noxc.md`

All source paths above refer to commit `a8940d27826849a526c3e918126ac6dd6ef571d1` in `mburakmmm/nox-lang`.
