# ADR-0001: synchronous layered core

- Status: accepted for Phase 0/1
- Date: 2026-11-05

## Context

Obsidian must be safe before it is feature-rich. Logging mixes pure transformations, lifecycle-sensitive I/O and potentially recursive user callbacks.

## Decision

Build a synchronous core first. Keep levels, fields, records, redaction and formatting independent from sink I/O. Capture one immutable record, sanitize it, then fan the sanitized snapshot out to sinks. Do not add a default global logger.

## Consequences

- Deterministic tests can inject clocks and sinks.
- File and async lifecycle work cannot contaminate the record model.
- Async remains disabled until a separate go/no-go ADR proves safe queue and worker ownership.
