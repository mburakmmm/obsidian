# API status

Status: Phase 11 beta candidate for the documented synchronous core. The normative protected symbol list is `public-api.md`; optional adapters remain preview.

## Levels

Consumer import form:

```nox-fragment
import obsidian.level
from obsidian.level import INFO, WARNING
```

Repository tests use the same `obsidian.*` imports as consumers and execute through the hermetic downstream-package harness described in ADR-0006.

| Name | Numeric severity | Notes |
|---|---:|---|
| `TRACE` | 5 | Most verbose event level |
| `DEBUG` | 10 | Debug event level |
| `INFO` | 20 | Informational event level |
| `WARNING` | 30 | Canonical warning level |
| `WARN` | 30 | Alias accepted at input; canonical output is `WARNING` |
| `ERROR` | 40 | Error event level |
| `CRITICAL` | 50 | Critical event level |
| `OFF` | 100 | Threshold sentinel; never an emitted event |

`is_enabled(event_level, threshold)` compares numeric severity. Invalid values fail closed by returning `False`. `canonical_name` and `from_name` raise `ValueError` for unknown values/names and use fixed messages that do not include caller input.

Obsidian's `WARNING` maps to the standard library's `WARN` severity without changing `nox.log` behavior. Tests restore the prior `nox.log` module threshold after checking the mapping.

The documented logger, record, sink, context, configuration and formatter surface is now a beta candidate. Importable helpers absent from `public-api.md` remain internal.

## Beta field and record model

`FieldValue` is an explicit tagged class for null, string, integer, float and boolean values. It does not accept arbitrary objects or call their structural representation. Nested lists/objects are compile-time rejected and remain deferred pending recursive-type, ownership and redaction experiments.

`LogField` rejects empty, oversized, control-character and reserved keys. Error messages are stable categories and do not echo the rejected key.

`LogRecord` captures timestamp milliseconds, numeric/canonical severity, logger name, message, event fields, context and `obsidian.log.v1` schema version. It deep-copies caller-owned field lists and returns clones from accessors. NOX 2.1.0 has no private or language-level immutable class fields, so this is a snapshot-isolation contract rather than an enforcement claim against deliberate mutation of underscore-prefixed internals.

Messages and scalar string fields are limited to 65,536 Unicode code points. `fields` and `context` are independently limited to 256 unique keys. NaN and positive/negative infinity are rejected by `FieldValue`; null, string, integer, finite float and boolean are the supported scalar kinds.

## Beta formatters

`format_text.format_record(record)` returns one human-readable physical line without a trailing newline. It renders the captured UTC time as RFC 3339 with millisecond precision, flattens context/event fields with event-field precedence, sorts keys, JSON-quotes ambiguous keys/string values and escapes all ASCII controls plus DEL. Phase 2 emits no ANSI sequences, so `NO_COLOR` and non-TTY output cannot receive color codes.

`format_json.format_record(record)` returns exactly one JSON object followed by exactly one newline. The fixed emitter order is:

1. `timestamp`
2. `timestamp_ms`
3. `level`
4. `logger`
5. `message`
6. `fields`
7. `context`
8. optional `request_id`
9. optional `trace_id`
10. optional `span_id`
11. `schema_version`

Absent optional identifiers are omitted without leaving placeholders; the remaining relative order is unchanged. `fields` and `context` are separate key-sorted objects. Scalar JSON kinds are retained; null and empty string remain distinct. The pinned NOX parser exposes every JSON number as `float`, so parser-based round trips cannot prove integer precision above 2^53 even though `JsonWriter.write_int` emits an integer token. Consumers parse by property name and ignore unknown properties according to `schema.md`.

Both formatter entry points apply the default sanitizer before encoding. This is defense in depth for direct use; logger dispatch still sanitizes before any sink boundary. If the default sanitizer fails, direct formatting receives a fixed placeholder record rather than the unsafe input.

## Beta synchronous logger

`Logger(name, threshold, clock, redactor=None, raise_on_error=False)` is an explicit instance with no global default. Disabled events return `False` before reading the clock or constructing a record. Enabled events capture the clock once, apply the selected redactor, and synchronously dispatch cloned snapshots to registered `Sink` implementations. A redactor exception or failed result drops the event, increments a saturating failure counter and returns `False` without exposing the unsafe record or exception text.

The TRACE convenience method is named `trace_event`. At the pinned compiler revision, the natural `trace` spelling passes type-checking but produces a duplicate LLVM symbol; `log(TRACE, ...)` remains the equivalent semantic path. No future `trace` alias is promised by the beta contract.

`add_sink` returns a monotonically increasing registration ID and installs an allow-all `TRACE` route. `add_sink_with_filter(sink, minimum_level, filter)` adds a validated per-sink numeric threshold and a `LogFilter`. One logger accepts at most 64 active registrations, and identifiers fail closed before exceeding `2147483647`. `ExactLoggerNameFilter` is case-sensitive exact equality; it is not a prefix matcher. Threshold rejection happens before invoking the filter. Filters receive sanitized clones, so mutation cannot affect sink output. A filter exception or re-entry fails only that route closed and later routes still run.

`remove_sink` affects only its registration and does not close the removed sink; the caller resumes lifecycle ownership and must close it. `flush` targets currently registered sinks. `close` attempts every registered sink once and becomes closed even if a sink fails. Route mutation/reconfiguration during redaction, filtering, sink dispatch, flush or close is rejected with a fixed category. Recursive log/flush/close calls terminate and increment bounded diagnostics. Default write failures make `log` return `False`; flush/close failures are visible in diagnostics. Explicit `raise_on_error=True` raises only fixed sanitized categories after write routing. It never exposes callback exception text.

`diagnostics_snapshot()` returns bounded counters for redaction, filtering, sink write/flush/close and recursion failures. Individual counters and `total_failures()` saturate at `2147483647`. No record, path, configuration value or exception text is stored.

`Sink` exposes lifecycle methods, a stable name and a bounded-storage capability flag. `MemorySink` is a bounded drop-oldest ring with an explicit drop counter and clone-returning snapshots. Built-in drop, flush, write and rotation counters saturate at `2147483647`. Recursive logger operations from a sink are rejected before another callback traversal begins. No lock is held while calling a sink because the current dispatcher is synchronous and lock-free.

`RedactionPolicy(additional_keys)` extends the fixed case-insensitive denylist with copied, validated application keys. `DefaultRedactor` masks scalar fields/context plus assignments, HTTP credential headers, bearer tokens, URL userinfo and sensitive query parameters. Nested values are deliberately unsupported. Rotation uses the same formatter/redaction boundary; future exception and async records must enter it as well. See `docs/security.md` and ADR-0008 for limitations.

## Beta context and configuration

`Logger.bind(fields, request_id="", trace_id="", span_id="")` returns a `BoundLogger` snapshot view. It delegates to the parent dispatcher and does not own/close sinks. Initial and nested context snapshots are limited to 256 fields. A later binding replaces same-key bound context, and event fields take precedence by removing same-key context before record capture. Caller lists and field values are copied.

Correlation IDs are optional strings limited to 128 ASCII letters/digits plus `-`, `_`, `.` and `:`. Text output renders request, trace and span IDs in that fixed order. JSON emits non-empty identifiers as optional top-level properties after `context` and before `schema_version`. No implicit global or task-local propagation exists.

`LoggerConfig`, `RedactionConfig`, `FormatterConfig` and `SinkConfig` are validated typed models. `factory.build_logger` rejects more than 64 sink configs before resource construction, preserves allow-all routing, builds the complete synchronous sink set before exposing a logger and closes already-built sinks if construction fails. `Logger.reconfigure` replaces only name, threshold, redactor and error policy after all replacement objects exist; current sink registrations are preserved. Typed route configuration is deferred on the pinned compiler; use explicit `add_sink_with_filter` calls after constructing sinks.

Stable seeded sampling, hierarchical prefix filters and source metadata are not implemented. The pinned docs expose no selected stable hash or caller/file/line inspection API; Obsidian does not fabricate either capability.

`with_threshold_environment` reads only an explicitly named variable and handles missing `nox.os.getenv` values through `OsError`. Invalid values raise a fixed sanitized category. There is no implicit `.env`, home, file or network configuration. `QueueConfig` is deliberately absent because the Phase 7 audit reached a no-go decision on the pinned toolchain.

## Async dispatch

There is no async logging API on the pinned NOX 2.1.0 baseline. `Logger.log`, convenience methods, sink writes, `flush` and `close` remain synchronous. Obsidian does not expose a background worker, queue capacity, overflow policy or async lifecycle counters. The Phase 7 capability audit was rerun unchanged on 2.1.0 and remains a no-go. See ADR-0011 for the executable evidence and re-evaluation conditions.

## Optional ecosystem adapters

`integration.request_completion_fields` constructs the framework-neutral allowlisted request fields. Methods must be 1–16 uppercase ASCII letters, status must be 100–599 and duration is clamped to zero. `safe_route_name` accepts at most 256 control-free characters and applies message redaction; `safe_correlation_id` returns an empty value for an invalid identifier. Completion severity is `INFO` for 1xx–3xx, `WARNING` for 4xx and `ERROR` for 5xx.

`obsidian.adapters.nyx.NyxRequestLogging` provides router-compatible before/after methods with task-local monotonic timing. `bind_request` and `log_completion` read only Nyx's request ID, HTTP method and response status; raw targets and payloads are not collected.

`obsidian.adapters.aether.AetherRequestLogging` returns an `InterceptorFns`. It keeps timing and optional route metadata in Aether's request-scoped value bag. `set_route_name` is explicit and must receive a stable application-defined name/template, never a raw path.

`obsidian.adapters.quartz.QuartzCapture` is a bounded sink wrapper intended for tests. It delegates lifecycle/storage to `MemorySink` and provides fixed-message count, level and secret-sentinel assertions.

These modules are not imported by core and require the corresponding consumer dependency only when selected. Exact tested revisions and examples are documented in `docs/ecosystem.md`; API compatibility beyond them is not claimed.

## Beta synchronous I/O sinks

`ConsoleSink(name, target, format_kind)` requires an explicit target and formatter. `CONSOLE_STDOUT` supports text or JSON output. `CONSOLE_STDERR` raises a sanitized `SinkError` because the pinned NOX API has no stderr write primitive. Console `flush()` is a logical no-op, not a process stdio flush.

`FileSink(name, allowed_root, relative_path, format_kind, create_parent)` owns one append-only `FileWriter`. It validates portable relative paths, rejects recognized credential-key filename components, canonicalizes existing/created parents under the allowed root, rejects tested traversal/symlink escapes, writes one encoded record per unbuffered call and closes idempotently. File `flush()` is a logical no-op and does not imply `fsync` durability.

`FORMAT_TEXT` and `FORMAT_JSON` select the existing deterministic formatters. Both sinks re-enter those sanitizer-backed formatters; file/path/write failures are exposed as stable `SinkError` categories without echoing paths or record data. Plain `FileSink` storage is unbounded; `RotatingFileSink` supplies an explicit size budget. A trusted application-owned root is required because the pinned API has no `lstat`, no-follow open or race-free directory-relative open.

## Beta size rotation

`RotationPolicy(max_bytes, max_archives)` validates a positive byte limit up to 1 TiB and an archive count from 0 through 1000. `RotatingFileSink(name, allowed_root, relative_path, format_kind, create_parent, policy)` rotates before a write would cross the encoded-byte boundary and rejects a single record larger than the limit. It reports bounded storage and exposes write/rotation/current-size/archive counters for diagnostics and tests.

Archives use `<basename>.NNNNNNNN`. `retention_candidates(root, relative_path, policy)` returns the deterministic oldest-first names that would be removed without mutating the filesystem; `apply_retention` deletes exactly that validated owned set. Matching symlinks, directories and canonical-path mismatches are rejected. `rotating_file_sink_config` integrates the sink with the typed factory.

The contract is single-process only. Time-based rotation, compression, durable sync and hostile-directory race resistance are not supported. See ADR-0010 and `docs/recovery.md`.
