# ADR-0003: non-recursive failure policy

- Status: proposed; Phase 1 compile tests required
- Date: 2026-11-05

## Context

Sink, formatter, redaction and callback failures must be observable without recursive logging or secret leakage.

## Decision direction

The default policy will not raise from ordinary logging calls. It will record bounded sanitized counters and may write a minimal sanitized emergency diagnostic through a path that cannot invoke the logger again. An explicit `raise_on_error` mode may be offered for tests and callers that opt in.

Redaction failure always fails closed regardless of the general error policy. No original unsafe record is emitted.

## Required proof

- Re-entry detection terminates recursion.
- Failure counters are bounded and thread/backend semantics are honest.
- Custom callbacks are invoked without internal logging locks.
- Diagnostics never contain raw record, config, path or exception values.
