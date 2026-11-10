# Public API inventory

Status: published `v0.9.0-beta.1` synchronous beta contract for NOX 2.1.0. This inventory is normative; importable symbols not listed here are internal and have no compatibility guarantee.

## Stability labels

| Label | Contract |
|---|---|
| **beta** | Protected within a released minor line. Before 1.0, an incompatible change requires a documented minor version and migration path. |
| **preview** | Executable and tested only against the exact listed dependency revisions; signatures may change before promotion to beta. |
| **internal** | No compatibility promise, even if the NOX module system permits importing it. |

Underscore-prefixed fields, helper functions absent from this inventory and injected test hooks such as rotation renamers are internal. Consumers must not mutate object fields directly; use constructors, accessors and snapshot methods below.

For a listed class, the constructor and non-underscore members described in this document or `api.md` are protected unless stated otherwise. `FieldValue` uses typed scalar factories rather than its tagged constructor; `SinkConfig` uses the named sink-config factories; `DiagnosticsSnapshot` and `BoundLogger` are obtained from `Logger`; and the optional `RotatingFileSink` renamer argument is an internal test hook. These exclusions keep representation and failure-injection details out of the beta contract.

## Beta core modules

| Module | Documented symbols |
|---|---|
| `obsidian.version` | `current_version()` |
| `obsidian.level` | `TRACE`, `DEBUG`, `INFO`, `WARNING`, `WARN`, `ERROR`, `CRITICAL`, `OFF`; `is_valid`, `is_event_level`, `canonical_name`, `from_name`, `is_enabled` |
| `obsidian.fields` | `FieldValue` readable scalar properties and `clone`; `LogField(key, value)`, readable `key`/`value` and `clone`; `null_value`, `string_value`, `int_value`, `float_value`, `bool_value`; scalar kind constants and `MAX_STRING_FIELD_LENGTH` |
| `obsidian.clock` | `Clock`, `SystemClock`, `FakeClock`; `FakeClock.now_ms`, `set_ms`, `advance_ms` |
| `obsidian.record` | `LogRecord`; `LOG_SCHEMA_VERSION`, `MAX_MESSAGE_LENGTH`, `MAX_FIELDS_PER_SECTION`; record scalar properties, `field_count`, `context_count`, `field_at`, `context_at`, `fields_snapshot`, `context_snapshot`, `clone` |
| `obsidian.logger` | `Logger`; `MAX_SINKS`; `is_enabled`, `add_sink`, `add_sink_with_filter`, `remove_sink`, `log`, `bind`, `trace_event`, `debug`, `info`, `warning`, `error`, `critical`, `flush`, `close`, `is_closed`, `redaction_failure_count`, `diagnostics_snapshot`, `reconfigure` |
| `obsidian.context` | `BoundLogger`, `LogContext`; `MAX_CORRELATION_ID_LENGTH`, `MAX_CONTEXT_FIELDS`; context snapshots/binding and the BoundLogger logging, binding, flush and lifecycle-observation methods |
| `obsidian.diagnostics` | `DiagnosticsSnapshot`, `MAX_DIAGNOSTIC_COUNT`; category accessors and `total_failures` |
| `obsidian.sink` | `Sink` protocol with `sink_name`, `write`, `flush`, `close`, `is_closed`, `is_bounded` |
| `obsidian.filter` | `LogFilter`, `AllowAllFilter`, `ExactLoggerNameFilter`; `allows` and exact-name accessor |
| `obsidian.redact` | `Redactor`, `RedactionPolicy`, `RedactionResult`, `DefaultRedactor`; `default_redactor`, `sanitize_message`, `sanitize_fields`, `sanitize_record`, `is_sensitive_key` |
| `obsidian.sink_error` | `SinkError` and its fixed sanitized `message` category |
| `obsidian.sink_format` | `FORMAT_TEXT`, `FORMAT_JSON`, `is_valid_format`, `encode_record` |
| `obsidian.format_text` | `format_record` |
| `obsidian.format_json` | `format_record` |
| `obsidian.sinks.memory` | `MemorySink`; lifecycle, count/drop/flush accessors, clone-returning `record_at` and `snapshot` |
| `obsidian.sinks.console` | `CONSOLE_STDOUT`, `CONSOLE_STDERR`, `ConsoleSink`; sink lifecycle and `write_count` |
| `obsidian.sinks.file` | `FileSink`; sink lifecycle and `write_count` |
| `obsidian.rotation` | `RotationPolicy`; `MAX_ROTATION_BYTES`, `MAX_RETAINED_ARCHIVES`; `archive_name`, `archive_names`, `retention_candidates`, `apply_retention` |
| `obsidian.sinks.rotating_file` | `RotatingFileSink`; sink lifecycle, `write_count`, `rotation_count`, `current_size_bytes`, `archive_count` |
| `obsidian.config` | `RedactionConfig`, `FormatterConfig`, `SinkConfig`, `LoggerConfig`; sink-kind constants; `memory_sink_config`, `console_sink_config`, `file_sink_config`, `rotating_file_sink_config`, `with_threshold_environment` |
| `obsidian.factory` | `build_logger` |
| `obsidian.integration` | `safe_http_method`, `safe_route_name`, `safe_correlation_id`, `safe_http_status`, `safe_duration_ms`, `request_completion_level`, `request_completion_fields` |

`FieldValue` instances are created through the typed scalar factory functions; direct tagged construction is not part of the beta contract. `LogRecord` is public because custom sinks and filters receive it, but callers should normally create records through `Logger`. `FakeClock` is a supported deterministic test utility, not a production clock.

## Preview adapters

| Module | Preview surface | Tested dependency |
|---|---|---|
| `obsidian.adapters.nyx` | `NyxRequestLogging`, `bind_request`, `log_completion` | Nyx `v0.24.0` / `b4ef854badb8478f074e4b89fd864b48633b023c` |
| `obsidian.adapters.aether` | `AetherRequestLogging`, `bind_request`, `log_completion`, `set_route_name` | Aether `v0.9.0` / `d283a3badd1585dba1c58685dfa4d376f59262b8` |
| `obsidian.adapters.quartz` | `QuartzCapture` and its sink/count/assertion methods | Quartz `v0.9.15` / `a8e0b9b2d3e71bb61d192362b158a74c3212f38` |

Preview adapters do not expand the core dependency graph and are not covered by beta source-compatibility promises outside the pinned revisions.

## Explicitly absent

There is no default global logger, async logger/queue, exception/stack capture, source metadata, network sink, config-file loader, time-based rotation, cross-process rotation, stderr implementation, recursive field value or tracing engine. Absence is part of the published beta scope; code must not depend on speculative spellings for these capabilities.

