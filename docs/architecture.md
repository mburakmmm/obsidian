# Architecture

Status: Phase 0 design baseline. Public APIs are not frozen.

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

## Boundaries

- Records are immutable snapshots captured once before fan-out.
- Threshold checks happen before expensive record/field construction.
- Redaction happens before any sink, callback or diagnostic boundary.
- Formatting/filtering/redaction remain pure and separate from I/O.
- Formatters consume one captured record and never re-read clocks or identifiers.
- Text flattens context with event-field precedence; JSON keeps `fields` and `context` namespaced and deterministically sorted.
- The MVP dispatcher is synchronous and bounded sinks are preferred.
- File rotation and asynchronous dispatch are later gated capabilities.
- There is no default global logger in v0.1.

## Module layout

NOX 2.0.143 resolves package files from the repository root, so modules remain small root-level files such as `level.nox`, `record.nox`, `logger.nox`, `format_text.nox` and `format_json.nox`; sink modules live under `sinks/`. Package-internal imports use the manifest name (`obsidian.*`) so they remain correct regardless of a consumer's chosen dependency alias. Because the pinned compiler does not resolve that self-name for a root-project build, repository tests and examples execute in an isolated downstream consumer created by `scripts/run-package-suite.sh`.

There is no `__init__.nox` facade convention in the audited module contract. Public entry points will be documented by module path rather than simulated with Python package behavior.

## Lifecycle model

Logger ownership is explicit. Sinks have documented write/flush/close behavior, close is idempotent, and failures follow a configured non-recursive policy. User callbacks must not execute while holding a lock required by logging.

## Security model

All output paths consume a sanitized record. A redaction failure drops or replaces unsafe content and increments a sanitized bounded diagnostic counter. Raw records must never be passed to untrusted sinks merely because a formatter failed.

## Portability model

LLVM and QBE compile the same source but have different scheduler and argument behavior. Synchronous semantics are portable. Concurrency support is conditional and requires separate evidence on both backends.
