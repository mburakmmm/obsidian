# ADR-0013: optional ecosystem adapters and safe request metadata

- Status: accepted for the Phase 9 integration preview
- Date: 2026-11-07

## Context

Obsidian must support NOX ecosystem consumers without reversing the dependency direction. Nyx and Aether expose different request lifecycle APIs, while Quartz is a test framework rather than a production runtime. Adding any of them to the core manifest would make every Obsidian consumer fetch a framework it may not use and would violate the project contract.

Request integrations also sit on a confidentiality boundary. Raw paths, query strings, headers, bodies and response bodies may contain credentials or personal data. A convenience adapter must not make those values fields by default.

## Decision

Framework-specific code lives under `adapters/` and is compiled only when a consumer imports that module. The root `nox.json` keeps `requires: []`. Core module `integration.nox` contains only framework-neutral normalization for HTTP method, status, duration, explicit route names and correlation identifiers. `scripts/audit-dependencies.sh` rejects Nyx, Aether or Quartz imports outside the optional adapter/probe/example boundaries.

The first published adapter set is tested against these immutable resolutions:

| Adapter | Tested tag | Resolved commit |
|---|---|---|
| Nyx | `v0.24.0` | `b4ef854badb8478f074e4b89fd864b48633b023c` |
| Aether | `v0.9.0` | `d283a3badd1585dba1c58685dfa4d376f59262b8` |
| Quartz | `v0.9.15` | `a8e0b9bd2d3e71bb61d192362b158a74c3212f38` |

Nyx uses a per-task monotonic start value in `NyxRequestLogging`; Aether stores the same value in Aether's request-scoped value bag. Both emit the fixed message `request completed`. Their default event fields are only normalized method, status and non-negative duration. A route is included only when application code supplies an explicit stable name or template. It is length/control validated and passed through the message sanitizer. Raw request target, path, query, headers, bodies and response content are never read into the record. Correlation IDs that fail Obsidian validation are omitted instead of breaking the request.

HTTP 1xx–3xx completion events use `INFO`, 4xx uses `WARNING` and 5xx uses `ERROR`. Invalid statuses become numeric `0` at `INFO`. The middleware returns the original response unchanged. Default logger infrastructure failures remain observable through the logger result/diagnostics and do not replace application responses; an application that explicitly enables strict `raise_on_error` accepts the corresponding exception behavior.

`QuartzCapture` is a bounded `MemorySink` facade with clone-returning accessors and fixed-message assertions. Its secret assertion scans the captured record directly, including logger/message, string field/context keys and values, and correlation IDs. It does not add Quartz to production core and is not a substitute for the full security suite.

Each adapter has an isolated downstream consumer probe and a compiling example on LLVM and QBE. The ordinary package suite copies but does not import adapters, proving that core use remains functional when framework packages are absent.

## Consequences

- Consumers add only the framework dependency required by the adapter they import.
- Adapter compatibility is claimed only for the exact tested tags/commits and NOX 2.1.0 matrix.
- Route names are explicit allowlisted metadata, not automatic URL capture.
- Nova, Feather, Atlas, Rune, Chronos, Ember, VAULT, Pulse and Aura adapters remain deferred until their public APIs are audited and stable enough for independent tests.
- The adapter directory is part of the package artifact, but unimported optional modules do not affect the core dependency graph.
