# Phase 10 safety closeout

Status: local P0/P1 closeout candidate on NOX 2.1.0; supported remote matrix evidence pending.

This audit covers the advertised synchronous Obsidian core, its built-in sinks, size rotation and the pinned Nyx/Aether/Quartz adapters. It does not promote disabled or explicitly unsupported capabilities into the support contract.

## Closed findings

| Area | Finding | Resolution and evidence |
|---|---|---|
| Callback lifecycle | A sink callback could append routes while the dispatcher traversed the live list; lifecycle callbacks could recursively call `flush` or `close` | ADR-0015 blocks callback-time mutation and guards all callback-invoking logger operations. Unit tests prove bounded termination, fixed diagnostics and continued healthy-route processing on LLVM/QBE. |
| Route resources | The logger route registry had no explicit count ceiling and registration identifiers had no exhaustion policy | Maximum 64 active registrations; factory validation occurs before sink construction; identifiers fail closed before exceeding `2147483647`. |
| Context resources | `LogContext` copied an arbitrarily large caller list before the record limit applied | Initial and nested context binding reject more than 256 fields; enabled oversized events fail before clock capture/collision work. |
| Long-running counters | Memory/file/console/rotation observable counters used unchecked increments | Counters now saturate at `2147483647`; regression coverage includes drop/flush saturation and the shared helper remains covered by diagnostics tests. |
| Secret-bearing paths | A mixed-case credential directory component followed by `/` was not recognized | Fixed by commit `e5936ed`; deterministic and 2,048-case seeded corpora pass on both local backends and supported CI. |

## Re-audited invariants

- The logger captures one record and sanitizes it before filters or sinks receive clones.
- Redaction, filter, sink and lifecycle exceptions produce fixed categories and bounded counts; exception text is not retained.
- Recursive log/lifecycle calls and callback-time mutation cannot grow the active route loop.
- Memory storage, route count, record/context fields, diagnostics and rotation retention have explicit bounds.
- Factory construction either returns a complete logger or closes every sink built by that failed attempt.
- File and rotation paths use fixed errors, exact owned archive names and canonical component confinement within a trusted root.
- Async dispatch remains absent; no queue, worker or shared-buffer lifetime is claimed.

## Documented unsupported boundaries

The following remain unsupported capability limits, not claims of completed behavior:

- hostile-directory race resistance without `openat`/no-follow primitives;
- cross-process or time-based rotation, durable `fsync`, stderr and recoverable console write errors;
- shared-logger thread safety and async dispatch;
- disk-full simulation and a guarantee against partial operating-system writes;
- recursive structured fields, arbitrary prose-secret discovery and stack/source inspection;
- Windows, platforms or backends absent from the recorded matrix.

These limits remain release-visible in `docs/compatibility.md`, `docs/security.md` and `docs/operations.md`. A future feature entering one of these boundaries requires a new ADR and matching negative/security/lifecycle tests.

## Verification gate

The closeout becomes final only after the complete package suite, three expected compile-fail fixtures, capability audit, dependency/import checks, optional adapters, benchmark smoke and file/rotation stress smoke pass on macOS arm64, Linux x64 and Linux arm64 with LLVM and QBE. Until that run is recorded here and in `todo.md`, the Phase 10 P0/P1 gate remains open.
