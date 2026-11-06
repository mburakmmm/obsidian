# ADR-0012: sanitized sink routing and bounded diagnostics

- Status: accepted for Phase 8 internal API
- Date: 2026-11-07

## Context

Phase 8 requires exact logger filtering, per-sink thresholds and observable infrastructure failures without exposing an unsafe record or exception text. Filters and sinks are user-extensible callbacks. They can throw, mutate their input or attempt to call the same logger recursively.

## Decision

`Logger.add_sink` remains the compatibility path and installs an allow-all filter at `TRACE`. `add_sink_with_filter` adds a route with a validated numeric minimum level and a structural `LogFilter`. `ExactLoggerNameFilter` performs a case-sensitive equality check; hierarchical matching is not implied.

The logger captures and redacts once before routing. Each filter receives a clone of the sanitized record. A false result skips only that route. A thrown filter or filter re-entry fails that route closed, increments a saturating counter and cannot prevent later routes from running. A filter mutation cannot alter the snapshot delivered to a sink.

`DiagnosticsSnapshot` exposes only bounded integer counters for redaction, filter, sink write, sink flush, sink close and recursion failures. It stores no record, path, configuration value or exception message. Each counter and the aggregate total saturate at `2147483647`.

The default logger policy records diagnostics and returns `False` from `log` when routing or sink writes fail. Flush and close continue across failures; close still becomes idempotently closed. `raise_on_error=True` is an explicit test/operator mode and raises only fixed `SinkError` categories after all write routes have been attempted. Redaction always remains fail-closed.

Typed factory routing is deferred. Compile/runtime probes found that widening `SinkConfig`, wrapping it in another config class and copying the same values into a scalar route class all produced invalid optimized test binaries on NOX 2.0.143. The proven Phase 8 API is therefore explicit programmatic `add_sink_with_filter`; the existing all-or-nothing factory keeps allow-all routing.

No internal logging lock exists in the synchronous dispatcher, so filters and sinks are not called under one. The re-entry guard remains active for redactors, filters and sinks. No emergency console/file callback is added; the sanitized counter snapshot is the supported diagnostic channel.

## Deferred

- Seeded sampling is absent because the pinned public docs do not provide a selected stable hash contract and Phase 8 does not need sampling to satisfy its gate.
- Source metadata is absent because no public caller/file/line inspection API was found.
- Hierarchical logger prefixes, audit profiles and tamper-resistance claims require separate designs and tests.
- Typed factory route configuration requires a newer pinned compiler or a separately proven representation.
- These counters are synchronous instance state and do not establish shared-logger thread safety.
