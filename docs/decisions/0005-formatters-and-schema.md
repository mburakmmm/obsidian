# ADR-0005: formatter boundaries and JSONL schema

- Status: accepted for internal Phase 2 API
- Date: 2026-11-05

## Context

Obsidian needs deterministic human text and machine-readable JSONL without relying on map iteration, arbitrary object stringification or per-sink clock reads. The pinned `JsonWriter` safely escapes strings and preserves scalar JSON kinds, but it does not validate container nesting and will accept non-finite float input that could produce invalid JSON.

## Decision

- A captured `LogRecord` is the only formatter input; formatters never read a clock.
- `format_common.format_timestamp` renders captured epoch milliseconds as UTC RFC 3339 with exactly three fractional digits.
- JSONL has a fixed top-level order: `timestamp`, `timestamp_ms`, `level`, `logger`, `message`, `fields`, `context`, `schema_version`.
- `fields` and `context` remain separate JSON objects. Keys are lexicographically sorted so output is deterministic without depending on map behavior.
- Text output flattens context and event fields. Event fields win on cross-section collisions, then the result is sorted by key.
- Scalar strings use `JsonWriter`/`dump_string`; no untrusted JSON token is assembled by naive concatenation.
- NaN and positive/negative infinity are rejected when a `FieldValue` is constructed. Unknown tagged values fail closed.
- Message and scalar string values are limited to 65,536 Unicode code points. Fields and context are each limited to 256 unique keys.
- Formatter entry points repeat the baseline sanitizer. Logger dispatch already sanitizes before sinks; the second application makes direct internal formatter use safe under the currently supported scalar policy.
- Text has no ANSI path in Phase 2. It escapes backslash, line breaks, tabs, ASCII controls and DEL and therefore always emits one physical line.

## Consequences

JSON numbers retain integer/float JSON kinds, but the pinned parser exposes numbers as `float`; integers above 2^53 therefore cannot be asserted losslessly through that parser. Nested arrays/objects remain deferred until a recursive owned `FieldValue` model is proven. Size limits are code-point limits rather than encoded-byte limits; byte budgets belong to sink configuration in later phases.
