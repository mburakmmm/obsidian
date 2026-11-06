# ADR-0008: fail-closed redaction boundary

- Status: accepted for the Phase 4 scalar event model
- Date: 2026-11-06

## Context

Every sink and callback must receive only sanitized records. The current NOX field model deliberately supports scalar values only, while free-text messages can contain assignments, HTTP headers, bearer tokens, URL userinfo and query credentials. Redaction itself can fail and must never fall back to the original record.

## Decision

- `RedactionPolicy` owns the fixed default denylist plus at most 64 validated additional keys. Matching is case-insensitive and policy inputs are copied.
- `DefaultRedactor` masks sensitive scalar fields and context values, then sanitizes logger names and messages before sink fan-out.
- Message handling covers quoted and unquoted assignments, `Authorization`, `Cookie`, `Set-Cookie`, bearer tokens, URL userinfo and sensitive query parameters. It uses public `nox.log.mask_assignments` and bounded stdlib regex operations.
- Messages without a sensitive-key, bearer or URL marker bypass the matcher. This preserves arbitrary UTF-8 and control characters for the formatter's escaping/JSON encoding contract.
- A redactor exception or failed result drops the event before dispatch. `Logger` increments a saturating, sanitized failure counter and returns `False`; it never emits exception text or the original record.
- The logger re-entry guard covers record capture, redaction and sink dispatch, so a redactor or sink callback cannot recursively invoke the same logger.
- Direct formatter use applies the default redactor again. Internal failure produces a fixed placeholder record, never the unsafe input.
- The scalar-only `FieldValue` model rejects nested collections at compile time. Nested support remains disabled until recursive ownership and redaction are designed together.
- File names containing recognized credential-key components are rejected. Phase 6 rotation derives archive names only from the already validated basename plus a numeric suffix and reruns the synthetic-sentinel matrix.

## Consequences

- Custom sinks, memory snapshots, console output and file output receive the same pre-sink sanitized snapshot through `Logger`.
- Arbitrary secrets with no recognizable key, header, bearer prefix, URL-userinfo position or explicit additional key cannot be discovered reliably. Callers must not log request bodies, full header maps or opaque private objects.
- Exception metadata and async queue records do not yet exist. Runtime configuration and Phase 6 rotation enter the same boundary and have dedicated sanitized-error/sentinel tests; future output paths must do the same.
