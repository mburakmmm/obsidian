# AGENTS.md — OBSIDIAN

> **Project:** Obsidian — structured logging and observability foundations for the NOX ecosystem
> **Status:** Planned / experimental; this document is the implementation contract, not a claim that APIs already exist.
> **Language:** NOX 2.x, with minimal Zig/NNI glue only where unavoidable.
> **Reference inspiration:** Loguru's ergonomic API; not a clone or API-compatibility promise.
> **Applies to:** Every AI coding agent, contributor, test author, reviewer, and release workflow working in this repository.

## 0. Mission and non-negotiable principles

Build **Obsidian**, a small, standalone, production-grade NOX logging library that offers a convenient developer API and robust structured, secure, configurable output. Obsidian is the shared logging foundation for Nyx, Aether, Nova, Feather, Atlas, Quartz, Rune, Chronos, Ember, VAULT and later Pulse. It **must not depend on those frameworks**. They may depend on Obsidian.

The initial scope is **logging**, not a full OpenTelemetry collector, distributed tracer, metrics engine, APM service, or database. Provide interoperability hooks for those future systems without implementing them prematurely.

**Priority order:** semantic correctness > confidentiality > reliability > portability > bounded resource use > ergonomics > performance > feature count.

1. Preserve existing `nox.log` semantics; Obsidian **wraps and extends**, not forks or replaces, the standard library.
2. Never print or serialize a secret by default. Security tests are release blockers.
3. Logging must never introduce uncontrolled recursion, unbounded memory growth, deadlocks, or silent data loss.
4. Output must be deterministic where expected; inject clock, sink and identifiers in tests.
5. Public interfaces must be explicitly versioned and documented. Internal APIs may evolve.
6. Do not assume Python features or APIs exist in NOX. Check the current compiler and stdlib before writing code.
7. All implementations must work with NOX's static type checker and documented ownership model.
8. NOX code is the default. Zig/NNI may be used only after a documented capability gap and explicit boundary design.
9. A green CI badge is not evidence of untested behavior. Each advertised feature needs a behavioral test.
10. Do not claim benchmarks, platform support, thread safety, or sink durability without measurements/tests.

## 1. Verified NOX platform facts and compatibility constraints

Consult the authoritative upstream repository at `https://github.com/mburakmmm/nox-lang` and pin the tested compiler revision. Relevant documented APIs at planning time:

- `nox.log.format(level, message)`, `redact(message, secrets)`, `mask_assignments(message, keys)`, `set_level`, `level`, `enabled`, `debug/info/warn/error`. **Current `nox.log` emits to stdout**, has a module-level level setting, and does not implement file/network sinks.
- `nox.json`: `JsonWriter`, `dump_string`, `parse`, typed accessors. JSON strings must be escaped using documented facilities.
- `nox.fs`: `open_append`, `FileWriter.write`, `close`, `metadata`, `rename`, `create_dir_all`; `write_string_atomic` uses a predictable temporary path and must not be mistaken for a cross-process-safe rotating-log implementation.
- `nox.os`: `getenv` raises `OsError` for missing variables; `set_var`, `current_dir`.
- `nox.time`: consult current documentation for monotonic and wall-clock APIs before implementing timestamps or durations.
- NOX async tasks use `spawn`/`await`; QBE is cooperative/single-threaded while LLVM may run tasks on multiple workers. Do not infer thread safety from a QBE-only test.
- NOX runtime/ABI internals are private and unstable. Never import `__nox_*` symbols or assume ARC/object layouts. Use public NOX APIs or documented NNI.

**Required upfront compatibility audit:** Inspect current `docs/stdlib/log.md`, `json.md`, `fs.md`, `os.md`, `time.md`, `thread.md`/`atomic.md`, `docs/language/concurrency.md`, `docs/internals/architecture.md`, and the installed `noxc` version. Record findings in `docs/compatibility.md`. If a needed capability is absent, choose an explicitly documented fallback or defer the feature. Never invent a method to make code appear complete.

## 2. Scope: what Obsidian is and is not

**Core responsibilities:** levels, structured events, context binding, filtering, text/JSON formatting, stdout/stderr and file sinks, rotation/retention, redaction, configurable error policy, bounded async queue (when supported), observability IDs, deterministic testing, NOX ecosystem adapters.

**Deferred/optional:** network sinks, OTLP exporters, distributed tracing, log ingestion UI, dashboard, log search server, compression, encryption at rest, email/webhook alerts, metrics aggregation. They require separate ADRs and explicit dependencies; they must not delay the stable core.

**Out of scope:** replacing `nox.log` in NOX stdlib; implementing a general-purpose event bus; building a secret store (VAULT owns that); building a tracing engine (Pulse owns that); automatically capturing arbitrary private data.

## 3. Proposed repository layout

```text
obsidian/
├── AGENTS.md
├── README.md
├── CHANGELOG.md
├── LICENSE
├── nox.json
├── src/
│   └── obsidian/
│       ├── __init__.nox             # adapt to verified NOX package conventions
│       ├── logger.nox               # logger facade, binding, options
│       ├── level.nox                # level model and comparisons
│       ├── record.nox               # immutable event snapshot
│       ├── context.nox              # explicit context and propagation
│       ├── fields.nox               # typed field representation
│       ├── filter.nox               # filters and sampling policies
│       ├── format_text.nox          # human-readable formatting
│       ├── format_json.nox          # canonical JSONL formatting
│       ├── redact.nox               # masking and secret handling
│       ├── sink.nox                 # sink contract and dispatcher
│       ├── sinks/
│       │   ├── console.nox
│       │   ├── file.nox
│       │   └── memory.nox           # testing and in-process use
│       ├── rotation.nox
│       ├── queue.nox                # optional bounded async dispatch
│       ├── config.nox
│       ├── diagnostics.nox
│       └── integration.nox
├── examples/
│   ├── hello.nox
│   ├── json_logging.nox
│   ├── request_context.nox
│   ├── redaction.nox
│   └── file_rotation.nox
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── concurrency/
│   ├── security/
│   ├── golden/
│   └── performance/
├── docs/
│   ├── compatibility.md
│   ├── architecture.md
│   ├── api.md
│   ├── security.md
│   ├── operations.md
│   ├── ecosystem.md
│   ├── decisions/
│   └── migration.md
└── .github/workflows/ci.yml
```

Adjust filenames to NOX's *actual* package/import rules. Never create an unbuildable Python-style package layout simply because it looks familiar.

## 4. Public API design contract

The following is **conceptual API design**; spellings/signatures must be proven with compile tests and documented before stabilization.

```text
logger = obsidian.logger("service.auth")
logger.info("login succeeded", fields={"user_id": "u-123"})
logger.warning("retry scheduled", fields={"attempt": 2})
logger.error("database unavailable", fields={"error_kind": "timeout"})
request_logger = logger.bind({"request_id": "req-42"})
request_logger.info("request completed", fields={"status": 200})
```

Do **not** copy this pseudocode into `.nox` files without adapting to NOX's actual supported types, overloads, keyword arguments, dict values and constructors. A typed `LogField`/`FieldValue` representation may be necessary for mixed-type structured fields.

Required concepts:

- `Logger` is an explicit instance, not hidden mutable global state.
- `LoggerConfig` describes threshold, sinks, formatter, redaction, overflow and error policy.
- `LogRecord` is a snapshot of event time, severity, message, logger name, structured fields, context, optional exception data and source metadata.
- `bind(fields)` returns a new logger/context view and must not mutate unrelated loggers.
- `with_options(...)`/`configure(...)` must have documented copy-vs-mutation semantics.
- `add_sink` returns a stable registration identifier; `remove_sink` removes only that sink; `flush` and `close` have explicit guarantees.
- `is_enabled(level)` avoids expensive formatting on disabled events.
- Public level names: `TRACE`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`, `OFF`. `WARN` may be an alias of `WARNING` only if documented. Map to `nox.log`'s `WARN` carefully; never change stdlib behavior.
- Configured threshold compares numeric severity, not lexicographic strings.
- `log(level, message, fields)` is the common internal path for convenience methods.
- Every API defines whether failures raise, return a status, or are recorded by a diagnostics callback.

**Do not expose a default global logger in v0.1.** A convenience default may be added later only with a clear lifecycle and safe initialization story; explicit logger instances remain primary.

## 5. Event model and schema

A record must contain:

| Field | Type/meaning | Requirement |
|---|---|---|
| `timestamp` | UTC timestamp, RFC 3339 where supported | Mandatory for production output |
| `timestamp_ms` | integer epoch milliseconds if reliable | Optional but useful |
| `level` | canonical severity name | Mandatory |
| `logger` | stable component name | Mandatory |
| `message` | human-readable message | Mandatory |
| `fields` | structured typed key/value collection | Mandatory, possibly empty |
| `context` | bound metadata snapshot | Mandatory, possibly empty |
| `request_id` | opaque correlation ID | Optional |
| `trace_id` | trace correlation ID | Optional |
| `span_id` | span correlation ID | Optional |
| `exception` | sanitized error metadata | Optional |
| `source` | filename/line/function, when available | Optional |
| `schema_version` | output schema version | Mandatory for JSONL |

Rules:

1. Capture the record **once** before sink fan-out; every sink sees the same event data.
2. Avoid re-reading the wall clock separately for each sink.
3. Preserve field types in JSON; do not stringify booleans, numbers, nulls or arrays merely for convenience.
4. JSONL emits exactly one valid JSON object and one newline per event; embedded newline characters are escaped inside strings.
5. UTF-8, quotes, control characters and non-ASCII data must survive round trips.
6. Reserved keys (`timestamp`, `level`, `message`, etc.) cannot be overwritten by user fields. Define a clear namespacing/collision policy.
7. Event ordering: per synchronous logger call order is preserved; cross-thread total order is **not** guaranteed unless a specific dispatcher provides it.
8. Never serialize raw stack pointers, native handles, arbitrary object memory or secret-bearing `repr` values.
9. A failure to capture source metadata must not prevent the log record from being emitted.
10. Fields are immutable snapshots; subsequent mutation of caller-owned maps must not change queued records.

## 6. Levels, filtering, sampling and routing

- Apply threshold checks **before** costly field serialization or message formatting.
- Apply redaction **before** handing records to any untrusted sink, callback, network transport or diagnostics channel.
- Support exact logger-name filtering first; hierarchical prefix rules (`app.http.*`) are a later feature with tests.
- Filters must be deterministic, side-effect-aware, and documented; a filter failure must not leak an unredacted record.
- Support per-sink level thresholds; a record may be sent to multiple sinks.
- Sampling is optional; if implemented, define stable sampling by key and deterministic seeded tests. Never sample away mandatory security/audit events unless explicitly configured.
- Audit logging is a separate policy profile, not merely `INFO` with a different name. Do not promise tamper resistance without a real mechanism.

## 7. Formatters

### Text formatter

- Human-friendly single-line output by default; multi-line exception output is explicitly opt-in.
- Example conceptual format: `2026-11-05T00:00:00.000Z INFO service.auth request_id=req-42 login succeeded`.
- Stable ordering for structured fields, consistent escaping, no ANSI when output is not a TTY or `NO_COLOR` is set.
- Console colors are opt-in or terminal-aware; no color codes in JSON/file output unless explicitly requested.
- Timestamp zone, precision and format are configurable within supported clock APIs.

### JSON formatter

- Output canonical, valid JSONL; use `nox.json.JsonWriter` or `nox.json.dump_string`, never naive string concatenation for untrusted values.
- Stable schema with `schema_version` and documented reserved names.
- Strict handling of non-finite floats and unsupported field types: reject or normalize with documented policy; never emit invalid JSON.
- Distinguish null from empty string and missing fields.
- Provide golden tests for exact JSON structure, not fragile incidental map ordering.

## 8. Sinks and lifecycle

Define a `Sink` contract in terms supported by NOX: `write(record or encoded_line)`, `flush`, `close`, plus `name`/capabilities. Do not require structural interfaces unsupported by the current type checker; use an explicit class/protocol/adapter design verified by compile tests.

### Console sink

- stdout/stderr selection explicit; recommend stderr for application diagnostics.
- Honor `NO_COLOR`; do not assume ANSI support.
- Synchronous flush policy documented; write failures follow configured error policy.

### File sink

- `nox.fs.open_append` for append semantics; explicit close.
- Optional directory creation must be deliberate and constrained.
- File rotation based on bytes, UTC time interval or both **only after** reliable file size/clock primitives are verified.
- Rotation and retention must not delete files outside the configured log directory; reject traversal and unexpected symlinks in untrusted paths.
- Cross-process rotation safety is **not** assumed. Start with single-process ownership; document and test multi-process behavior before advertising it.
- If rename fails, do not silently lose the active file; surface a sanitized error and apply documented fallback.
- Retention must be deterministic and have a dry-run/testing mode; never delete unrelated files.
- Define durability honestly: `flush()` of a language buffer is not necessarily `fsync()` to stable storage.
- Bound maximum message size and disk usage when configured.

### Memory sink

- In-memory bounded ring buffer for tests and embedded diagnostics.
- Expose snapshot/copy, not mutable internal storage.
- Optional drop counter when capacity is exceeded.

### Custom sink

- Public registration with lifecycle contract and exception handling.
- Prevent recursive logging from a sink callback; detect re-entry and route to a minimal emergency diagnostic path or drop with a counter.
- Never call user-provided callbacks while holding a lock needed by logging itself.

## 9. Security, privacy and redaction — release blockers

Threat model: accidental leakage of credentials/PII in messages, structured fields, exceptions, context, sink errors, configuration, filenames and diagnostics.

- Use `nox.log.redact` and `mask_assignments` where appropriate, but **do not assume they detect all secret patterns**.
- Define a field-name denylist (e.g. `password`, `passwd`, `token`, `access_token`, `refresh_token`, `authorization`, `api_key`, `secret`, `cookie`, `set-cookie`, `private_key`) and configurable additional keys.
- Match key names case-insensitively with documented normalization; handle nested dictionaries/arrays recursively when supported.
- Apply redaction to **all** outputs, including JSON, console, file, exceptions, fallback diagnostics and third-party sinks.
- Mask HTTP `Authorization`, `Cookie`, `Set-Cookie`, database DSNs, connection URLs and common query-string credential parameters.
- Prefer allowlisting safe request metadata over logging entire request/response bodies or headers.
- Ensure secrets never appear in log file names, rotation names, error messages, crash reports, snapshots or test failure output.
- Never store plaintext secret fixtures in repository or CI logs. Use synthetic fixtures.
- Treat external sink addresses and configuration paths as untrusted. Do not enable remote network sinks by default.
- `Secret` wrapper or secret-typed field support may integrate with VAULT later, but Obsidian must remain independently usable.
- Document limitations: redaction cannot guarantee discovery of every arbitrary secret embedded in free text. Safe-by-default field filtering is mandatory.
- On redaction failure, **fail closed**: drop or replace unsafe content, increment a sanitized diagnostic counter; never emit the original record.
- Prevent log forging: escape embedded control characters in text output; JSON encoding handles JSON escapes.

**Security acceptance cases:** mixed-case credential keys; nested secrets; bearer tokens; URL credentials; multiline injection; Unicode; control characters; exception messages containing tokens; redaction failure; custom sink; rotation error; asynchronous queue; error fallback. No unmasked sentinel may appear in any captured output.

## 10. Concurrency and asynchronous dispatch

The MVP must have a correct **synchronous** dispatcher. Async mode is a separate milestone.

- Use a bounded queue with configurable `capacity` and overflow policy (`BLOCK`, `DROP_NEWEST`, `DROP_OLDEST`, `SYNC_FALLBACK`), where supported.
- Document blocking risk; do not allow a logging worker to block on its own full queue.
- Queue metrics: accepted, emitted, dropped, failed, pending, high-water mark.
- Define `flush(timeout)` as waiting for accepted records to be processed, not merely queue emptiness at one instant.
- Define `close(timeout)` and shutdown semantics; make close idempotent.
- Handle cancellation, worker panic/exception, partial write and process termination explicitly.
- Do not free shared buffers or atomic cells while a worker may still access them. Track worker ownership and join/completion.
- Test genuine overlapping producer calls on LLVM; QBE tests must validate cooperative behavior without claiming OS-thread parallelism.
- If a safe multi-producer implementation cannot be proven with current NOX APIs, ship synchronous mode and mark async unsupported. **Never substitute fake concurrency counters or synthetic workers for real concurrency tests.**
- Ordering guarantees must be scoped (per producer, per sink, or global queue) and verified.
- Do not perform arbitrary user callbacks under internal locks.

## 11. Context propagation and correlation

- `logger.bind(fields)` produces an immutable context-bearing logger view.
- Per-request context must not leak across requests or fibers; prefer explicit propagation (`request_logger`) in the MVP.
- Context precedence: event fields > bound context, except protected/reserved metadata. Document collision behavior.
- `request_id`, `trace_id`, `span_id` are opaque strings; validate size and allowed characters to prevent log forging.
- Context inheritance across `spawn` is **not assumed**; if automatic propagation is added, demonstrate it with isolation tests on QBE and LLVM.
- No implicit process-global mutable request context.
- Future Pulse integration should map IDs without inventing a tracing system inside Obsidian.

## 12. Exception and error reporting

- Provide explicit `logger.exception(...)` only when current NOX exception inspection supports it; otherwise offer `logger.error(..., error_kind, safe_message)`.
- Never fabricate Python traceback APIs or stack inspection primitives.
- If stack traces become available, scrub file paths, environment details and secret-bearing exception text according to policy.
- Separate application errors from logging infrastructure failures.
- Default sink failure policy: non-recursive, sanitized emergency diagnostic and observable failure counter; choose `raise_on_error` only when caller explicitly opts in.
- Avoid broad `except` that silently swallows data loss.
- No logger call may invoke itself indefinitely through error handling.

## 13. Configuration

- Typed `LoggerConfig`, `SinkConfig`, `RedactionConfig`, `QueueConfig` and `FormatterConfig` models.
- Configuration must be validated before activation; invalid configuration leaves the existing logger functional.
- Provide an explicit builder/factory API first. JSON/TOML/YAML loading is optional and must use existing NOX parsers.
- No hidden auto-read of `.env`, arbitrary home directories or network locations.
- Environment overrides are explicit and documented; use `nox.os.getenv` with `OsError` handling.
- Runtime reconfiguration must be atomic from the caller's perspective: no half-installed sink sets, no leaked handles.
- Never echo secrets while printing configuration or validation errors.
- VAULT integration may supply config and secrets, but no hard dependency on VAULT.

## 14. Ecosystem integration contract

Obsidian's dependencies point **outward only to NOX stdlib and minimal approved utilities**. Integrations must be optional adapters in separate files/packages, never hard imports in the core.

| Consumer | Proposed integration | Forbidden coupling |
|---|---|---|
| Nyx | request logger, request/trace IDs, HTTP status/duration | Obsidian importing Nyx |
| Aether | middleware context, route diagnostics | Obsidian importing Aether |
| Nova | sanitized outbound HTTP timing/status | logging Authorization/body by default |
| Feather | query duration, sanitized query identifiers | raw SQL parameter/credential dumps |
| Atlas | data pipeline stage logs, row counts | logging sensitive table contents |
| Quartz | captured in-memory logs, assertions, test diagnostics | production core depending on Quartz |
| Rune | CLI console sink, no-color handling | replacing Rune console framework |
| Chronos | job ID and execution context | global job context leaking to other jobs |
| Ember | event/job correlation IDs | treating logging as event transport |
| VAULT | config/secret-aware redaction | importing VAULT into Obsidian core |
| Pulse | trace/span ID bridge, optional export adapter | implementing full tracing in Obsidian |
| Aura | structured diagnostics, platform-specific sink adapter | UI thread blocking / hard Aura dependency |

For each adapter, provide a minimal example, integration test and graceful behavior when the consumer is not installed.

## 15. Performance and resource budgets

Set budgets after collecting baselines; do not invent performance guarantees.

Measure at minimum:

1. Disabled DEBUG call overhead.
2. INFO console formatting throughput with output redirected.
3. JSONL encoding throughput and bytes/event.
4. File sink throughput and rotation pause.
5. Bounded queue throughput, p50/p95/p99 enqueue latency, drop counts.
6. Concurrent producer scaling on LLVM, and cooperative scheduler behavior on QBE.
7. Memory footprint under sustained load and slow/failing sink.
8. Startup and logger construction overhead.

Use a fixed benchmark fixture, report hardware/OS/compiler SHA/backend, warm-up policy, sample size and variance. Compare against `nox.log` baseline where meaningful. Do not compare stdout and file sinks as equivalent workloads. Include pathological long messages and Unicode.

## 16. Testing matrix and acceptance criteria

**Unit:** severity mapping; enabled thresholds; bind immutability; field precedence; reserved keys; text escaping; JSON round trip; timestamp injection; deterministic filters; sampling; config validation; sink registration/removal; idempotent close.

**Integration:** real stdout/stderr capture; file append; directory creation; rotation boundaries; retention; permission denied; disk-full simulation where feasible; reopen; cleanup after errors; no unexpected path traversal.

**Security:** complete redaction matrix from §9; secret sentinel must never appear in any sink output, fallback diagnostic or snapshot.

**Concurrency:** two or more producers actually overlap; queue backpressure; exact delivered/dropped accounting; flush/close under load; worker cancellation; no use-after-free; no deadlock; repeated stress loops.

**Differential:** where semantics overlap, compare `nox.log` output/level behavior against Obsidian's compatibility adapter; compare QBE/LLVM results for deterministic tests.

**Property/fuzz:** arbitrary UTF-8, JSON control characters, large fields, malformed config, unusual level names, nested field structures, rotation filenames. Prefer Quartz when stable and compatible, but tests must be runnable without requiring Quartz as a production dependency.

**Golden:** text/JSON schema, field ordering policy, exception sanitization, rotation naming, diagnostics. Normalize timestamps and temp paths using injected fixtures.

**CI:** Linux x64, Linux ARM64, Windows x64, macOS ARM64 as available; QBE and LLVM where supported. Explicitly mark unsupported backend/platform combinations as skips with reasons; never count skipped integration tests as executed. Report test-case and assertion totals separately.

**Release gates:** all supported matrix jobs green; zero unredacted secrets; no known P0/P1 safety bugs; documented public API; clean install from pinned NOX revision; successful examples; benchmark report; license; changelog; version/tag alignment.

## 17. Development phases — do not skip gates

### Phase 0 — Capability audit and scaffolding

- Pin compiler SHA and document stdlib APIs, package conventions and backend constraints.
- Create repository, manifest, README, architecture ADR and CI skeleton.
- Compile one minimal package import and one test on each supported backend.
- **Gate:** no speculative API usage; reproducible hello-world build.

### Phase 1 — Core event model and synchronous logger

- Implement levels, immutable record, logger names, threshold, explicit clock injection and memory sink.
- Add deterministic unit tests and golden fixtures.
- **Gate:** record construction and filtering correct; no hidden global state.

### Phase 2 — Text and JSONL formatters

- Implement safe encoding, stable schema and optional human-friendly text format.
- Cover Unicode, control chars, null and mixed typed fields.
- **Gate:** every JSONL line parses and retains types; no injection.

### Phase 3 — Console and file sinks

- Implement lifecycle, write/flush/close and failure policy.
- Test real filesystem, output capture, permission errors.
- **Gate:** no leaked handles; errors observable and sanitized.

### Phase 4 — Security baseline

- Implement field-aware masking, message redaction, nested values and fail-closed behavior.
- Test all sinks and diagnostics against synthetic secret sentinels.
- **Gate:** zero secret leaks; mandatory before publishing even an alpha release.

### Phase 5 — Context binding and configuration

- Add immutable `bind`, explicit request IDs, typed configuration and validation.
- **Gate:** parallel request contexts never leak; invalid reconfigure preserves previous logger.

### Phase 6 — Rotation and retention

- Implement single-process size-based rotation first, then optional time-based rotation.
- Test crash/restart behavior and safe file selection.
- **Gate:** no unexpected deletion, bounded storage under configured policy.

### Phase 7 — Async dispatcher (conditional)

- Only if public NOX concurrency primitives permit safe implementation.
- Implement bounded queue, backpressure, counters, flush/close and lifecycle.
- **Gate:** genuine producer overlap, worker completion and memory safety proven on LLVM; QBE behavior documented.

### Phase 8 — Advanced filtering and diagnostics

- Per-sink filters, sampling, source metadata where supported, sink failure counters.
- **Gate:** no recursion, bounded diagnostics, deterministic tests.

### Phase 9 — Ecosystem adapters

- Start with Nyx/Aether and Quartz; add others only when APIs are stable.
- **Gate:** zero reverse dependencies; each adapter independently tested.

### Phase 10 — Benchmarking and hardening

- Performance baselines, fuzzing, stress, long-running file/queue tests.
- **Gate:** published reproducible measurements; no open P0/P1 issues.

### Phase 11 — Beta API freeze

- Document API, migration guide, support matrix, limitations and schema version.
- **Gate:** stable API candidates pass compatibility and upgrade tests.

### Phase 12 — v1.0 stable

- Release after all applicable gates, signed/tagged provenance where infrastructure supports it.
- **Gate:** verified artifacts, release notes, examples and CI evidence match published commit.

## 18. Coding conventions for agents

1. Prefer small modules with explicit responsibilities; no monolithic `logger.nox` implementation.
2. Follow `noxc fmt`; verify compile with the pinned toolchain before committing.
3. Type every function and field according to NOX's rules; do not use dynamic Python idioms.
4. Keep pure formatting/filtering/redaction separate from I/O.
5. Inject clocks, sinks and IDs; avoid nondeterministic tests.
6. Never duplicate stdlib parsing or time logic when an existing safe API exists.
7. Avoid hidden module-level mutable state and implicit singletons.
8. Make close/flush semantics explicit and test idempotency.
9. Use errors with stable categories and sanitized messages; never include raw credentials.
10. Treat a skipped test as missing evidence; record it in the PR summary.
11. Any API design change requires docs, examples and tests in the same change.
12. Any performance optimization requires semantic regression tests before benchmark claims.
13. Do not modify NOX compiler/runtime as a shortcut; propose a separate upstream issue/ADR if required.
14. Preserve backward compatibility within a released major version unless a documented breaking release is approved.
15. Do not add external network calls, telemetry or automatic uploads without explicit opt-in.

## 19. Mandatory agent workflow

For **every** implementation task:

1. **Inspect:** read AGENTS.md, current code, compatibility doc, relevant NOX stdlib docs and tests.
2. **State scope:** identify phase, acceptance criteria, touched files, risks and dependencies.
3. **Design:** record significant trade-offs in an ADR; verify any uncertain language feature in a minimal compile test.
4. **Implement:** make the smallest coherent change, with no unrelated refactor.
5. **Test:** unit + integration + negative + security + backend-specific tests as appropriate.
6. **Review:** inspect resource ownership, secret exposure, race conditions, recursion, cleanup, error handling and cross-platform behavior.
7. **Document:** update API docs, examples, CHANGELOG and compatibility matrix where relevant.
8. **Report:** list changed files, exact commands/results, assertion counts, skipped tests, known limitations and next steps.

Never claim “implemented”, “thread-safe”, “secure”, “production-ready” or “tested on four platforms” unless supported by actual evidence. If a feature cannot be completed safely, leave it disabled with an explicit TODO and a failing/skip-tracked test, rather than a fake implementation.

## 20. Pull request checklist

- [ ] Matches the current phase and an approved public API contract.
- [ ] Compiles with pinned NOX toolchain.
- [ ] QBE and LLVM tested where applicable.
- [ ] All relevant tests run; assertion totals reported.
- [ ] No secrets in code, fixtures, logs or test output.
- [ ] Every output path goes through redaction.
- [ ] No unbounded queue, recursion or retention.
- [ ] No worker lifecycle or shared-memory lifetime hazards.
- [ ] File sink closes resources and handles write/rotation errors.
- [ ] No hard dependencies on Nyx/Aether/Aura or other ecosystem frameworks.
- [ ] Documentation/examples/CHANGELOG updated.
- [ ] CI status and tag/commit alignment verified.

## 21. Definition of done and release policy

A feature is **done** only if it is implemented in executable NOX, has passing positive/negative tests, meets security and lifecycle contracts, is documented, and passes supported backends. Documentation-only or mocked-only features are not done.

Versioning proposal: `0.1.x` synchronous core; `0.2.x` structured JSON/security; `0.3.x` file rotation/context; `0.4.x` optional async; `0.5.x` ecosystem integrations; `1.0.0` after API freeze and release gates. These are **planning milestones**, not already published versions.

Never silently retarget a published immutable release tag. A successful publish workflow is not proof of registry approval or downstream installation; verify both separately.

## 22. First actionable assignment

1. Create the repository skeleton and pin a NOX compiler commit.
2. Verify import/package syntax with an actual compiling `.nox` example.
3. Implement `Level`, `LogRecord`, `MemorySink`, `Logger` and synchronous dispatcher with explicit configuration.
4. Add a deterministic fake clock and 20+ meaningful test cases covering level filtering, binding, sink lifecycle and redaction.
5. Demonstrate a complete path: `Logger.info` → immutable record → redaction → formatter → memory sink and console sink.
6. Add a `docs/compatibility.md` table identifying what works on QBE/LLVM and which features are deferred.
7. Stop before file rotation or async implementation until Phase 1–4 safety gates pass.

**Success criterion:** a small NOX program can import Obsidian, log a structured and safely redacted event, and produce deterministic text/JSON output with passing tests and no dependence on Nyx, Aether or Aura.

---

**Primary references:**

- NOX source: https://github.com/mburakmmm/nox-lang
- NOX logging API: https://github.com/mburakmmm/nox-lang/blob/main/docs/stdlib/log.md
- NOX JSON API: https://github.com/mburakmmm/nox-lang/blob/main/docs/stdlib/json.md
- NOX filesystem API: https://github.com/mburakmmm/nox-lang/blob/main/docs/stdlib/fs.md
- NOX concurrency: https://github.com/mburakmmm/nox-lang/blob/main/docs/language/concurrency.md
- NOX architecture: https://github.com/mburakmmm/nox-lang/blob/main/docs/internals/architecture.md
