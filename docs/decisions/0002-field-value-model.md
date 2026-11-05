# ADR-0002: typed field value model

- Status: proposed; compile experiments required in Phase 1
- Date: 2026-11-05

## Context

NOX is statically typed and has no Python-style arbitrary mixed dictionary contract. JSON output must preserve scalar types and eventually support safe nested values.

## Proposed direction

Use an explicit tagged `FieldValue` representation rather than `dict[str, object]` or implicit stringification. Begin with string, integer, float, boolean and null. Nested arrays/objects require compile and ownership experiments before acceptance.

Caller-owned collections must be copied into immutable snapshots. Unsupported and non-finite values must be rejected or safely normalized according to documented policy; they must never produce invalid JSON or invoke arbitrary secret-bearing representations.

## Open questions

- Exact tagged representation supported cleanly by NOX 2.0.143.
- Recursive type support and snapshot cost.
- Integer precision at the JSON boundary, where parsed JSON numbers are doubles.
