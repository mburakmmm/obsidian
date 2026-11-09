# Architecture

Status: Phase 9 optional adapter preview verified in the supported CI matrix. Public APIs are not frozen.

## Dependency direction

```text
application / optional ecosystem adapter
                 ↓
          Obsidian public facade
                 ↓
 record + fields + levels + configuration
          ↓              ↓
 pure policy       synchronous dispatcher
 format/redact           ↓
                    sink contracts
                         ↓
              console / file / memory
                         ↓
                    NOX stdlib
```

Core Obsidian may depend on the pinned NOX standard library and separately approved minimal utilities. Nyx, Aether, Aura, VAULT, Pulse and other consumers must never be imported by core modules.

Framework-specific imports are confined to `adapters/`. Those modules are optional package leaves: an application imports one only after adding that framework dependency. `integration.nox` is the framework-neutral boundary for normalized request metadata, and the root manifest remains dependency-free. See ADR-0013.

## Boundaries

- Records are immutable snapshots captured once before fan-out.
- Threshold checks happen before expensive record/field construction.
- Redaction happens before any sink, callback or diagnostic boundary.
- Formatting/filtering/redaction remain separate from I/O; custom filters receive only a sanitized clone.
- Formatters consume one captured record and never re-read clocks or identifiers.
- Text flattens context with event-field precedence; JSON keeps `fields` and `context` namespaced and deterministically sorted.
- Bound logger views deep-copy explicit context and delegate to one sink-owning parent logger.
- Configuration is validated before activation; factory failures close resources created by that attempt.
- The MVP dispatcher is synchronous and bounded sinks are preferred.
- Size rotation uses a separate single-process sink; time-based rotation remains gated and async dispatch is unsupported on the pinned toolchain.
- There is no default global logger in v0.1.

## Module layout

NOX 2.1.0 resolves package files from the repository root, so modules remain small root-level files such as `level.nox`, `record.nox`, `logger.nox`, `format_text.nox`, `format_json.nox` and `integration.nox`; sink modules live under `sinks/`, and optional framework modules live under `adapters/`. Package-internal imports use the manifest name (`obsidian.*`) so they remain correct regardless of a consumer's chosen dependency alias. Because the pinned compiler still does not resolve that self-name for a root-project build, repository tests and examples execute in an isolated downstream consumer created by `scripts/run-package-suite.sh`.

There is no `__init__.nox` facade convention in the audited module contract. Public entry points will be documented by module path rather than simulated with Python package behavior.

## Lifecycle model

Logger ownership is explicit. Sinks have documented write/flush/close behavior and idempotent close. The default policy records saturating sanitized counters and continues to later routes; `raise_on_error` is explicit and emits only fixed categories. User filters and sinks do not execute while holding a logging lock. Log, flush and close re-entry is rejected and counted rather than recursively routed. Callback-time route mutation or scalar reconfiguration is rejected so a callback cannot grow or invalidate the list currently dispatching it.

A logger owns at most 64 active routes. Registration identifiers are monotonic, never reused and fail closed at their explicit ceiling. Initial and nested context snapshots are limited to 256 fields. Built-in observable sink counters saturate at the same fixed ceiling as diagnostics. See ADR-0015 and `hardening.md`.

`BoundLogger` does not expose `close`; it delegates writes and flush to its parent and cannot duplicate sink ownership. Runtime reconfiguration changes only validated scalar logger state and leaves the installed sink set intact. New sink sets are built through an all-or-nothing factory rather than mutating a live logger incrementally.

`RotatingFileSink` owns exactly one active handle. It closes before rename, reopens after rotation and never shares ownership with another Obsidian object. Retention is a separate deterministic policy over exact owned archive names; dry-run selection and deletion use the same candidate function.

## Security model

All logger output paths consume one pre-sink sanitized snapshot. A redactor exception or failed result drops the unsafe event and increments a saturating sanitized counter; direct default formatter use substitutes a fixed placeholder on internal redaction failure. Filters receive cloned safe records, and filter failures cannot expose or forward the original. Diagnostics contain counts only. Raw records are never passed to callbacks or sinks merely because redaction, filtering or formatting failed. Scalar nested values remain disabled instead of being stringified.

## Portability model

LLVM and QBE compile the same source but have different scheduler and argument behavior. Synchronous semantics are portable. Phase 5 verifies independent explicit context snapshots while two tasks overlap on both backends; QBE evidence is cooperative, and no shared-logger thread-safety claim is made.

The Phase 7 evidence includes an observed real LLVM worker overlap plus repeatable scalar atomic/channel communication, but not a portable Obsidian queue. The bounded continuous overlap probe reports the scheduling outcome instead of making an async no-go decision depend on every runner observing work stealing. QBE rejects class-valued `ThreadChannel` elements, channel sends require `await`, and the public API has no non-blocking send/receive, channel close, thread cancellation or timed join. ADR-0011 therefore keeps the dispatcher synchronous and forbids fake async counters or unjoined workers.
