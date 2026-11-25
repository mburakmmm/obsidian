# NOX compatibility baseline

Phase 16 selects NOX 2.2.70 for development and release tooling, with 2.1.0 retained for core consumer compatibility. The documented synchronous API and JSON schema remain at their v1 contracts.

## NOX 2.2.70 audit

The release tag resolves to `4dc061f8c8443f8575092c2652d1109b6f4697e9`. Checksums are pinned in CI for macOS ARM64, Linux x64 and Linux ARM64. The macOS archive used locally hashes to `0bcf719d1a5207e3470d8461f203b56ca086d04baaa2858cbdc6081ccebea7d1`.

| Upstream change | Obsidian integration |
|---|---|
| 2.2.39–2.2.62 self-hosting, ownership, list storage, codegen and formatter changes | Hosted list growth through an alias is a capability test. MemorySink keeps its portable ring implementation and owned record snapshots. |
| 2.2.63 framework fixes | Test typed cancellation of parked task-channel receivers and channel reuse. The parked thread-channel probe reports zero on both local backends. The documented lifecycle gaps and missing enqueue/join APIs keep async disabled. |
| 2.2.64–2.2.70 runtime and self-hosted type checking, HPy removal | Pin the stable compiler and validate the downstream package and release SBOM. Obsidian has no HPy dependency and no raw runtime-symbol integration. |
| Public terminal API on 2.2.70 | Opt-in stdout `TerminalSink` with error propagation and real flush. The legacy core remains usable with 2.1.0. |
| Filesystem and stderr | No applicable public stderr write, no-follow open or stable-storage sync was found. The existing file and rotation contract applies. |

Local packaged consumers passed 23 behavioral files with 486 assertion sites on NOX 2.1.0 and 2.2.70, each with LLVM and QBE. The separate owned-worker probe is skipped on 2.1.0 QBE because that code generator rejects the fixture. Nyx v0.24.0, Aether v0.9.0 and Quartz v0.9.15 probes and examples passed locally on both 2.2.70 backends. Installing the published `v1.1.0` through noxpkg resolved the expected `d3f189f` commit and passed the stable API, schema, import and version probes on both backends.

See the [upstream version range](https://github.com/mburakmmm/nox-lang/compare/v2.2.38...v2.2.70), [framework audit](https://github.com/mburakmmm/nox-lang/blob/v2.2.70/project/limitasyon-kaydi-2026-11.md), and [ADR-0011](decisions/0011-async-dispatch-no-go.md).

## Historical v1.0.0 toolchain

| Item | Pinned/observed value | Evidence |
|---|---|---|
| NOX source | `fd107b922c67a804520dc30f849039d977542f6c` | Annotated upstream tag `v2.1.0` resolves to this commit |
| Pinned test compiler | `noxc 2.1.0` | Verified release archive, `noxc --version` on 2026-11-07 |
| Release archive SHA-256 | `b96d286772da8eaa9d161824d7e4c91c34af85874045dbbae44909b607e65062` | Published checksum plus local `shasum -a 256 -c` |
| Compiler binary SHA-256 | `41296804cf1fe802e778f26940265dd1451dee5cdaf4838e7cc66c3329e49eb0` | Extracted pinned release binary |
| Ambient user compiler | `noxc 2.1.186` | Observed on 2026-11-16; candidate analysis only, not release evidence |
| Host | macOS 27.2, arm64 | `sw_vers`, `uname -m` |
| C compiler | Apple clang 21.0.0 | `clang --version` |
| Bundled QBE | present in the verified 2.1.0 release archive | filesystem inspection |
| Profile under test | `hosted` | filesystem, process and clock APIs are required |

The compiler reports a version but not its source SHA. The annotated `v2.1.0` tag resolves to the selected commit and contains no signature. Release assets include per-platform SHA-256 files; local verification and CI run `42308138269` checked the platform archives against their matching checksums on macOS arm64 and Linux x64/arm64. This is integrity evidence, not signed provenance. The ambient installation is now newer than the pin, so the isolated checksum-verified 2.1.0 archive remains the stable release evidence source.

CI run `42363929287` additionally passed the complete Phase 9 behavioral/integration matrix and the Phase 10 LLVM/QBE benchmark smoke step on macOS arm64, Linux x64 and Linux arm64. Shared-runner timings are deliberately not treated as performance baselines.

CI run `42395481106` passed the Phase 10 deterministic property addition on the same matrix: 18 behavioral files/396 assertions/0 skips per backend, 101 bounded corpus cases, three expected compile-fail fixtures, and the existing capability, adapter and benchmark-smoke checks.

CI run `42398683809` passed the rotation/path hardening addition on macOS arm64, Linux x64 and Linux arm64 with LLVM/QBE: 19 behavioral files/407 assertions/0 skips, 207 total deterministic property cases, three expected compile-fail fixtures, and the existing capability, adapter and benchmark-smoke checks.

CI run `42470080183` revalidated the same matrix after direct GitHub release URLs repeatedly returned HTTP 504 before tests could start. Pinned toolchain acquisition now uses the authenticated GitHub Release API with three bounded attempts, removes partial named assets before retrying, and still verifies the release-provided SHA-256 before extraction. This improves CI transport reliability without changing the compiler pin or provenance claim.

CI run `42471701337` added bounded file/rotation lifecycle smoke coverage on macOS arm64, Linux x64 and Linux arm64. Each job passed LLVM and QBE 8,000-event append and 8,000-event rotation rounds with timeout, exact JSONL/byte/retention checks and sentinel scanning, in addition to the existing 19 behavioral files/407 assertions/0 skips, capability probes, adapters and benchmark smoke.

CI run `42635939949` passed the fixed-seed fuzz addition on macOS arm64, Linux x64 and Linux arm64 with LLVM/QBE: 20 behavioral files/414 assertions/0 skips, 208 fixed property cases, 2,048 seeded fuzz cases and three expected compile-fail fixtures. The same jobs also passed capability probes, adapters, package import, benchmark smoke and 8,000-event file/rotation stress smoke. The corpus found and now guards a mixed-case sensitive-directory component followed by a path separator.

Commit `f71bbba` and CI run `42640500312` completed the Phase 10 P0/P1 closeout on macOS arm64, Linux x64 and Linux arm64 with LLVM/QBE. Every job passed 20 behavioral files/423 assertions/0 skips, three expected compile-fail fixtures, the capability audit, package import/dependency checks, pinned ecosystem adapters, benchmark smoke and 8,000-event file/rotation stress smoke. The added regressions cover callback-time mutation, recursive flush/close, route/context limits and saturating sink counters.

Commit `5d20822` and CI run `42765823934` passed the Phase 11 beta API/schema candidate on macOS arm64, Linux x64 and Linux arm64 with LLVM/QBE: 22 behavioral files/467 assertions/0 skips per backend. The two new downstream contracts compile the documented beta surface and verify required/optional `obsidian.log.v1` properties, scalar kinds and additive-property tolerance. Every job also passed three expected compile-fail fixtures, capability/import/dependency checks, pinned ecosystem adapters, all examples, benchmark smoke and 8,000-event file/rotation stress smoke.

Annotated tag `v0.9.0-beta.1` peels to exact commit `c2379fe493b8eb431220f8a5c2b1bd12b13f1867`. Tag-driven run `42774325476` repeated the complete supported matrix successfully on all three platforms before its obsolete registry-secret step failed. The tag was then submitted through the existing local `noxc` session and published as a GitHub prerelease without retargeting. This records matrix and submission evidence; it does not claim Windows support, registry moderator approval or a clean downstream registry install.

Phase 12 added a source-independent registry install gate. On 2026-11-10, checksum-verified `noxc 2.1.0` resolved the approved public-index name `obsidian` at `v0.9.0-beta.1`, locked exact commit `c2379fe493b8eb431220f8a5c2b1bd12b13f1867`, and passed the public API/schema/import/version probes on LLVM and QBE in an empty credential-free `NOX_HOME`. This now proves beta index visibility and clean downstream installation; it does not yet prove a future stable ref.

The developer-machine default compiler reported `noxc 2.1.14` during this audit. That observation does not move the project pin or expand support: every release-readiness command above used the explicit checksum-verified 2.1.0 binary. A compiler-pin update requires the full compatibility workflow and separate evidence.

Commit `c0dbaf2` and CI `42834838904` validated the Phase 12 registry-readiness harness and isolated capability-audit home on macOS arm64, Linux x64 and Linux arm64. All six LLVM/QBE combinations retained 22 behavioral files/467 assertions/0 skips, three expected compile-fail fixtures, seven capability probes, dependency/import checks, three ecosystem probes/36 checks, all examples, benchmark smoke and 8,000-event file/rotation stress smoke. This is readiness evidence, not an exact stable-release-commit claim.

Commit `ccc9e41` and CI `42968550569` passed the unchanged stable-candidate core contract on the same complete supported matrix with identical test totals. The renamed `stable_api_test.nox` also passed locally against the public `v0.9.0-beta.1` registry checkout on LLVM and QBE, proving the candidate does not depend on unreleased core APIs. At that point, stable release/version/tag evidence still remained pending; the following paragraph records its later completion.

Annotated tag `v1.0.0` peels to exact commit `e787ab6d8f6232ed9951e672cf38a88060e4cb0c`. Main CI `42971160582` and tag-driven release CI `42971769840` passed the complete supported matrix before the stable GitHub Release and public registry ref were verified. The clean registry gate resolved `v1.0.0` to that exact commit and passed version/API/schema/import contracts on LLVM and QBE under checksum-verified NOX 2.1.0.

## NOX 2.2.38 toolchain — 2026-11-21

The upstream tag points to `7f879fe0ecb972dc9994ee1e8f420d4aaa0cdd9a`. The candidate CI entries pin the published SHA-256 for macOS ARM64, Linux x64 and Linux ARM64. On the checksum-verified macOS ARM64 archive, both backends passed 22 behavioral files, all nine package examples and lock resolution. A clean registry consumer resolved Obsidian `v1.0.0` to `e787ab6d8f6232ed9951e672cf38a88060e4cb0c` and passed stable API, JSON schema, import and version checks on both backends.

[CI 44891584365](https://github.com/mburakmmm/obsidian/actions/runs/44891584365) passed all six compiler/platform jobs, with LLVM and QBE on each. The 2.2.38 lanes also passed the strict-spawn, path/clock and deterministic SBOM checks. Local full file stress completed 120,000 append events and 120,000 rotation events per backend with exactly four owned archives and 19,600 retained bytes per round.

The `v1.1.0` tag resolves to `d3f189f02e138431df419e1664e673e2df8a9733`. [Release 44892337383](https://github.com/mburakmmm/obsidian/actions/runs/44892337383) passed all six compiler/platform jobs, covering both backends per job with 22 behavioral files and 470 explicit assertion sites. The downloaded CycloneDX asset matched local regeneration byte for byte, with SHA-256 `94a709262c78907a1258104388598e5db1395cf04b0a1191c026a14a849d3933`. Credential-free installs of the published registry ref resolved the same commit and passed API, schema, import and version probes on LLVM and QBE with both compilers.

The candidate audit exercises real worker overlap and class transfer, verifies shared-spawn lint on explicit request context, and compares `safe_join` with the sink path policy. The stdlib helper permits some confined paths that Obsidian deliberately rejects. See [ADR-0011](decisions/0011-async-dispatch-no-go.md) for the blocked receive and shutdown findings and [performance](performance.md) for the compiler comparison.

## NOX 2.1.186 historical candidate audit — 2026-11-16

This audit does not move the stable pin. Upstream annotated tag `v2.1.186` peels to commit `5cf4f63d49cdf2a4a2c619a666df45799d7aac2e` and is unsigned. The published macOS ARM64 archive digest is `6195d697dacc1311a427ed3b09f1ec4aa626311f6155b84073969e1f0879fbb8`; the ambient compiler binary digest is `c45ce31d6b9cc94c20f182a44a6c243125ecafcf5d1fd440ca6d7acfb0c66218`, but the ambient installation was not independently reconstructed from that archive and is candidate evidence only. All mandatory stdlib, concurrency, architecture and package-tool documents read from upstream `main` were hash-identical to the `v2.1.186` tag.

| Area | 2.1.186 finding | Obsidian decision |
|---|---|---|
| Stable synchronous core | Local downstream LLVM and QBE suites each passed 22/22 behavioral files, all examples and exact lock resolution | Add a pinned 2.1.186 CI lane before changing the minimum or release pin |
| Registry metadata | `publish` accepts `--description`, comma-separated `--tags` and `--source`; `source: nox` is also valid in `nox.json` and is checked against a production-tree scan. The added field remained backward-compatible in checksum-verified 2.1.0 LLVM/QBE package suites | Declare `source: nox`, centralize canonical metadata in `scripts/publish-package.sh`, keep credentials outside the repository |
| Public noxpkg entry | Live index now records the canonical description, `logging`/`observability`/`structured-logging`/`security` tags and `source: nox` | Reverify metadata after every immutable release submission |
| SBOM and attestation | `noxc sbom` emits deterministic CycloneDX 1.5; this dependency-free project reports zero components and `nox:native=false`. Publish reported no signing key and therefore no signed attestation | Add an SBOM reproducibility/release-artifact task; do not create or register a signing key without an explicit provenance decision |
| Record transfer | Class-valued `ThreadChannel` ran successfully on both LLVM and QBE; both backends observed two overlapping workers | Update the capability audit and its documentation; this removes an old transport limitation but is not enough for a safe async logger |
| Queue lifecycle | `try_send` remains absent, timed `ThreadHandle.join` remains absent, synchronous `send` still fails codegen, and cancelling a worker blocked in `recv` deadlocks | Keep async dispatch disabled; require bounded overflow, wakeable close, timeout and exact accounting evidence before an API is added |
| Shared values | Hosted concurrency docs now describe memory-safe list/dict/class transfer and offer `--strict-spawn-shared` as a lint; compound scalar updates are still not atomic | Add the strict lint as candidate CI evidence and continue preferring channels/atomics for exact counters |
| Time | `now_ns` and `monotonic_ns` are public | Evaluate `monotonic_ns` for benchmark precision only; adding nanosecond record fields requires an explicit schema/API decision |
| Paths | `nox.path.safe_join` confines missing targets through canonical parent/component checks | Differential-test it against existing hostile path/symlink fixtures before considering replacement of proven confinement code |
| Logging, console and files | `nox.log`/`nox.console` remain stdout-only; file handles remain synchronous/unbuffered and expose no `fsync` or no-follow open | No stderr, stable-storage durability or hostile-directory race claim is unlocked |
| JSON | `nox.json` received internal lazy-tape performance work without a required Obsidian API change; `nox.yyjson` is a separate embedded-C option | Retain `nox.json` and the pure-NOX dependency boundary; do not add yyjson merely for novelty |

The current `docs/stdlib/thread.md` table still describes QBE thread arguments more narrowly than the tagged concurrency document and executable class-channel result. Obsidian will treat executable LLVM/QBE probes as the decision evidence and will not advertise a broader async contract until the upstream documentation and lifecycle primitives are consistent.

## Audited public APIs at the pinned revision

| Area | Observed public contract | Obsidian consequence | Status |
|---|---|---|---|
| `nox.log` | `format`, `redact`, `mask_assignments`, module-level threshold, stdout-only `debug/info/warn/error` | Wrap and extend; never change stdlib state implicitly | Phase 1 compile/behavior probes pass on LLVM/QBE |
| `nox.regex` / strings | bounded regex search/replace, escaping, Unicode string methods | Use fixed/escaped patterns; bypass matcher when no sensitive marker so arbitrary controls retain formatter semantics | Phase 4 header/Bearer/URL/query/control probes pass locally and in supported CI jobs |
| `nox.json` | `JsonValue`, typed accessors, `dump_string`, `JsonWriter` | Use writer/escaping; test writer nesting because it does not validate structure | Phase 2 JSONL/golden/typed round-trip probes pass on LLVM/QBE |
| `nox.fs` | synchronous `open_append`; unbuffered `write`; explicit/idempotent `close`; metadata size; rename/create/read/remove operations | File sinks close explicitly; size rotation uses byte metadata; `flush` is not `fsync` | Phase 6 size/rename/retention/restart probes pass locally and in supported CI on LLVM/QBE |
| `nox.path` | `canonicalize`, `join`, `strip_prefix`, components | Constrain file/retention paths against a canonical allowed root; reject raw controls before native path calls | Phase 10 CI `42635939949`: 107 deterministic rotation/path cases plus 512 seeded valid/hostile path cases and existing traversal/symlink probes |
| built-in `print` / `nox.console` | stdout only; no `file=` target, stdio flush or recoverable write-error channel | Support explicit stdout; reject stderr; document logical flush | Stdout exact-capture probe passes on supported CI jobs and locally; stderr blocked |
| `nox.os` | `getenv` raises `OsError` when absent; `current_dir`, `set_var` | Environment overrides require explicit `try/except OsError` | Phase 5 missing/valid/invalid env probes pass locally and in supported CI on LLVM/QBE |
| `nox.time` | UTC `DateTime`; wall `now_ms`; monotonic `Instant`; `boot_ms` | Inject wall clock for records and monotonic clock for timeouts/durations | Fake clock and epoch-to-RFC3339 probes pass on LLVM/QBE |
| `nox.thread` | awaited blocking `ThreadChannel.send/recv`; join-only `ThreadHandle`; QBE scalar element restriction | No portable record queue, non-blocking overflow or timeout-aware shutdown contract | Phase 7 executable probes pass locally and in supported CI; async no-go |
| `nox.atomic` | process-wide scalar cells; explicit handle reconstruction and one manual `free` after worker completion | Never free before a proven join; atomics cannot hold a record graph | Phase 7 scalar/lifetime probes pass locally and in supported CI on LLVM/QBE; LLVM overlap observation is reported separately |
| scheduler | LLVM M:N work-stealing; QBE cooperative tasks; `Task.cancel` is cooperative, while `ThreadHandle` has join only and channels expose no close/timeout contract | Backend-specific evidence is mandatory and does not imply portable queue semantics | LLVM real-worker peak 2 is proven but scheduling-sensitive; QBE scalar thread-channel probe passes locally and in supported CI |
| modules | project-root files; cyclic imports rejected; dependency aliases expose package modules; package self-imports use the manifest name | Root `.nox` modules plus `obsidian.*` self-imports; test through a consumer project | Full transitive downstream package graph passes on LLVM/QBE |
| tests | every `*_test.nox` is a program; failures raise/exit non-zero; `nox.test` has typed assertions and `TestSuite` | Count cases/assertions explicitly; capability and compile-fail probes remain separate from behavioral totals | Phase 11 candidate locally and in CI `42765823934`: 22 files/467 assertions/0 skips; three expected compile-fail fixtures remain separate |

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
| macOS arm64 / LLVM | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| macOS arm64 / QBE | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
| Linux x64 / LLVM | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| Linux x64 / QBE | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
| Linux arm64 / LLVM | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Async no-go revalidated; shared-logger thread safety remains unclaimed |
| Linux arm64 / QBE | Pass | Pass | Phase 11: 22 files/467 assertions/0 skips, beta API/schema contracts, 208 fixed + 2,048 seeded cases, 7 capability probes and 3 ecosystem probes/36 checks; CI `42765823934` | Scalar thread-channel/atomic lifecycle passes; async remains disabled |
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
