# ADR-0009: Explicit context views and validated configuration

- Status: accepted for the Phase 5 candidate
- Date: 2026-11-06

## Context

Obsidian needs request-scoped metadata without a process-global request context, and it needs configuration that cannot leave a live logger half-mutated. A bound view must not duplicate ownership of sinks: copying a logger with its sink list would make `close()` ownership ambiguous and could close a file handle twice.

NOX 2.0.143 provides classes, protocols, `spawn`/`await`, channels and explicit `nox.os.getenv` failure through `OsError`. It does not provide language-enforced immutable fields. The current synchronous dispatcher also has no proven cross-thread shared-logger synchronization.

## Decision

`Logger.bind` returns `BoundLogger`, which owns a deep-copied `LogContext` and delegates emission and flush to the original logger. A bound view intentionally has no `close()` method and therefore never owns shared sinks. Nested binding returns another snapshot; event fields remove same-key context fields before capture. Reserved correlation names remain protected by `LogField` validation.

`request_id`, `trace_id` and `span_id` are optional, bounded ASCII identifiers. They accept letters, digits, `-`, `_`, `.` and `:` and are emitted as top-level JSON properties or fixed-order text attributes. There is no implicit task-local or global context.

`LoggerConfig`, `RedactionConfig`, `FormatterConfig` and `SinkConfig` validate and copy their inputs. `factory.build_logger` constructs all configured sinks before exposing the logger; if construction fails, already-built sinks are closed and a fixed `SinkError` category is raised. A cleanup failure has its own fixed observable category rather than being silently swallowed. `Logger.reconfigure` validates/builds replacement scalar state before assigning name, threshold and redactor. It deliberately leaves the existing sink registrations untouched.

Environment overrides are opt-in through `with_threshold_environment(config, name)`. Missing variables preserve the base configuration via explicit `OsError` handling. Invalid values produce a fixed error and are never echoed. No file, home directory or network configuration is read automatically.

## Consequences

- Context data is snapshot-isolated from caller mutation and from other views.
- Sink lifecycle has one owner: the parent logger.
- The factory provides all-or-nothing construction for the supported sink set.
- Runtime sink-set replacement, config-file loaders and `QueueConfig` remain unavailable until their own lifecycle/capability gates.
- The concurrency test proves two overlapping NOX tasks keep independent explicit context snapshots on LLVM and cooperative QBE. It does not claim that simultaneous calls through one shared `Logger` are thread-safe.
