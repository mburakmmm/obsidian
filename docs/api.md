# API status

Status: internal development API for `0.1.x`; not frozen and not published.

## Levels

Consumer import form:

```nox-fragment
import obsidian.level
from obsidian.level import INFO, WARNING
```

Local repository tests omit the dependency alias and import `level` directly.

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

No logger, record, sink or formatter API is public yet.

## Internal field and record model

`FieldValue` is an explicit tagged class for null, string, integer, float and boolean values. It does not accept arbitrary objects or call their structural representation. Nested lists/objects remain deferred pending recursive-type and ownership experiments.

`LogField` rejects empty, oversized, control-character and reserved keys. Error messages are stable categories and do not echo the rejected key.

`LogRecord` captures timestamp milliseconds, numeric/canonical severity, logger name, message, event fields, context and `obsidian.log.v1` schema version. It deep-copies caller-owned field lists and returns clones from accessors. NOX 2.0.143 has no private or language-level immutable class fields, so this is a snapshot-isolation contract rather than an enforcement claim against deliberate mutation of underscore-prefixed internals.

## Internal synchronous logger

`Logger(name, threshold, clock)` is an explicit instance with no global default. Disabled events return `False` before reading the clock or constructing a record. Enabled events capture the clock once, apply the baseline sanitizer, and synchronously dispatch cloned snapshots to registered `Sink` implementations.

The TRACE convenience method is temporarily named `trace_event`. At the pinned compiler revision, the natural `trace` spelling passes type-checking but produces a duplicate LLVM symbol; `log(TRACE, ...)` remains the stable semantic path. This spelling is not frozen.

`add_sink` returns a monotonically increasing registration ID. `remove_sink` affects only that registration. `flush` targets currently registered sinks. `close` closes registered sinks once and is idempotent. Sink failures currently propagate so data loss is observable; the configurable diagnostics policy remains Phase 3/8 work.

`Sink` exposes lifecycle methods, a stable name and a bounded-storage capability flag. `MemorySink` is a bounded drop-oldest ring with an explicit drop counter and clone-returning snapshots. Recursive logging from a sink is rejected before a second record is captured. No lock is held while calling a sink because the current dispatcher is synchronous and lock-free.

The baseline sanitizer masks the required scalar sensitive field names case-insensitively and delegates `key=value` message masking to `nox.log.mask_assignments`. This is not the completed Phase 4 security surface: nested values, URLs, headers, exception/config/diagnostic paths and failure injection remain gated work.
