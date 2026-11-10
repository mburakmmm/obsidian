# JSONL schema compatibility

Status: `obsidian.log.v1` published beta contract in `v0.9.0-beta.1`.

Every encoded event is one UTF-8 JSON object followed by one newline. Embedded line breaks remain escaped within JSON strings. The canonical schema identifier is exported as `record.LOG_SCHEMA_VERSION`.

## Schema v1 properties

| Property | JSON kind | Presence | Meaning |
|---|---|---|---|
| `timestamp` | string | required | UTC RFC 3339 timestamp with millisecond precision |
| `timestamp_ms` | number with integer token | required | non-negative Unix epoch milliseconds |
| `level` | string | required | canonical event severity |
| `logger` | string | required | validated logger/component name |
| `message` | string | required | sanitized human-readable message |
| `fields` | object | required | sanitized typed event fields |
| `context` | object | required | sanitized bound context after event-key precedence |
| `request_id` | string | optional | opaque validated request correlation identifier |
| `trace_id` | string | optional | opaque validated trace correlation identifier |
| `span_id` | string | optional | opaque validated span correlation identifier |
| `schema_version` | string | required | exactly `obsidian.log.v1` |

Field/context values are JSON null, string, number or boolean. Arrays and nested objects are not emitted by v1. Empty `fields`/`context` objects are present; absent correlation IDs are omitted rather than emitted as empty strings.

The current emitter writes required properties in the table order, inserts present correlation IDs after `context`, and writes `schema_version` last. Field/context keys are lexicographically ordered. This determinism supports golden tests; consumers must still parse object properties by name because JSON object order is not semantic.

## Compatibility rules

Compatible v1 evolution may add an optional top-level property or clarify behavior without changing existing property kinds or meaning. Consumers must ignore unknown properties. A v1 emitter may omit only properties explicitly marked optional.

The following require a new schema identifier such as `obsidian.log.v2`:

- removing or renaming a required property;
- changing a property's JSON kind or existing semantic meaning;
- changing scalar `fields`/`context` into a recursive representation without a versioned transition;
- reinterpreting timestamp, level or correlation identifier formats incompatibly.

Package SemVer and schema versions are related but independent. A package may add support for a new schema without removing v1; removing an advertised schema follows the public API compatibility policy. See ADR-0016 and `tests/compatibility/schema_v1_test.nox`.

