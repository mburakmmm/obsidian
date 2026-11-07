# Security model and redaction limits

Status: Phase 4 scalar boundary, Phase 8 filter/diagnostic extensions and Phase 9 optional adapters are verified in the supported CI matrix.

## Protected output paths

`Logger.log` captures one record, runs the configured internal redactor and only then clones the sanitized snapshot to sinks. Memory, stdout console and append-only file sinks therefore receive no raw record through the logger path. Text and JSON formatters apply the default sanitizer again for defense in depth when called directly.

The default denylist is case-insensitive:

`password`, `passwd`, `token`, `access_token`, `refresh_token`, `authorization`, `api_key`, `secret`, `cookie`, `set-cookie`, `private_key`.

`RedactionPolicy` accepts up to 64 additional portable keys. Duplicate/default keys are rejected after lowercase normalization. Sensitive scalar fields are replaced with the string `***`; safe scalar types remain unchanged.

Free-text masking covers:

- quoted and unquoted `key=value` and `key:value` forms;
- HTTP `Authorization`, `Cookie` and `Set-Cookie` lines;
- standalone bearer tokens;
- URL userinfo such as `scheme://user:password@host`;
- sensitive query parameters following `?` or `&`.

Text formatting escapes control characters to prevent physical-line forging. JSON uses `JsonWriter`, so embedded newlines and controls remain escaped inside one JSONL object.

## Fail-closed behavior

If redaction throws or returns a failed result, `Logger` drops the event, increments a saturating counter and returns `False`. It does not pass the raw record to a filter or sink and does not expose the redactor exception message. Filters receive only sanitized clones. Filter exceptions/re-entry fail closed, are counted without their messages and do not prevent later routes from processing the safe snapshot. The re-entry guard is active during redaction, filtering and sink dispatch. Direct default sanitization replaces an internal failure with a fixed `[REDACTION_FAILED]` record containing no user fields or context.

Diagnostics contain only saturating counts by fixed category. They never store record text, fields, exception values, paths or configuration. Strict mode raises fixed categories only. There is no automatic emergency console/file output and no diagnostics callback that could form a second logging path.

Sink/path errors use fixed categories and do not echo paths or record contents. Control characters are rejected before native path and secret-pattern helpers run; recognized credential-key components are then rejected in file names. The allowed file root must still be trusted because the pinned NOX API cannot provide race-free no-follow open semantics.

## Deliberate limits

Redaction cannot discover every arbitrary secret embedded in prose. Do not log full request/response bodies, complete header maps, raw SQL parameters, private objects or production exception strings. Prefer explicit allowlisted metadata and configure application-specific keys.

Nested arrays/objects are not accepted by the scalar `FieldValue` model. This is a safe rejection, not recursive redaction support. Typed in-process configuration is validated with fixed errors; explicit environment threshold parsing never echoes the supplied value. Size-rotated active/archive output and injected rename failures are covered by synthetic-sentinel tests. Config-file loading, exception/source metadata, time rotation, sampling and diagnostics callbacks are not implemented. Phase 7 explicitly disables async dispatch, so no queue output path exists; any future re-evaluation must extend and rerun the complete sentinel matrix before it can be advertised.

No claim is made for encrypted storage, tamper resistance, cross-process file ownership or secret discovery in arbitrary encodings.

## Optional adapter boundary

Nyx and Aether integrations emit a fixed completion message plus allowlisted method, status and duration fields. They never copy raw path/query/header/body/response data into a record. Route metadata is absent unless application code explicitly supplies a stable name or template; it is bounded, control-checked and sanitized. Invalid correlation IDs are omitted. Quartz secret assertions scan the captured snapshot and use fixed failure text so a failing assertion does not echo the sentinel.

These controls reduce accidental collection but do not make arbitrary route names safe. Applications must not pass raw framework paths or targets to the explicit route API. See `docs/ecosystem.md` and ADR-0013.

## Testing rules

Only synthetic sentinel strings may appear in tests. Security tests cover mixed-case/default/custom keys, HTTP headers, bearer tokens, URL/query credentials, Unicode, multiline input, custom and memory sinks, file output, console output, failure injection and snapshot isolation. The Phase 10 deterministic property corpora additionally check every C0 control plus DEL in messages and file paths, selected multi-byte Unicode, maximum-size scalar strings/messages, fixed-error malformed configuration, exact archive ownership and component-boundary confinement. Nested values remain rejected at the static type boundary by `tests/compile_fail/nested_field_value.nox`; this is not a claim of recursive redaction support. A failed assertion must use a sanitized label rather than placing the sentinel in its failure message.

Report real vulnerabilities through the private process described in [`../SECURITY.md`](../SECURITY.md); never open a public issue containing credentials or production logs.
