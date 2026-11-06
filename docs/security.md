# Security model and redaction limits

Status: Phase 4 scalar logging boundary verified locally and in the supported CI matrix; Obsidian remains unreleased and experimental.

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

If redaction throws or returns a failed result, `Logger` drops the event, increments a saturating counter and returns `False`. It does not pass the raw record to a sink and does not expose the redactor exception message. The re-entry guard is active during redaction as well as sink dispatch. Direct default sanitization replaces an internal failure with a fixed `[REDACTION_FAILED]` record containing no user fields or context.

Sink/path errors use fixed categories and do not echo paths or record contents. Recognized credential-key components are rejected in file names. The allowed file root must still be trusted because the pinned NOX API cannot provide race-free no-follow open semantics.

## Deliberate limits

Redaction cannot discover every arbitrary secret embedded in prose. Do not log full request/response bodies, complete header maps, raw SQL parameters, private objects or production exception strings. Prefer explicit allowlisted metadata and configure application-specific keys.

Nested arrays/objects are not accepted by the scalar `FieldValue` model. This is a safe rejection, not recursive redaction support. Typed in-process configuration is validated with fixed errors; explicit environment threshold parsing never echoes the supplied value. Size-rotated active/archive output and injected rename failures are covered by synthetic-sentinel tests. Config-file loading, exception metadata, time rotation, diagnostics callbacks and async dispatch are not implemented yet; each must extend and rerun this matrix before it can be advertised.

No claim is made for encrypted storage, tamper resistance, cross-process file ownership or secret discovery in arbitrary encodings.

## Testing rules

Only synthetic sentinel strings may appear in tests. Security tests cover mixed-case/default/custom keys, HTTP headers, bearer tokens, URL/query credentials, Unicode, multiline input, custom and memory sinks, file output, console output, failure injection and snapshot isolation. A failed assertion must use a sanitized label rather than placing the sentinel in its failure message.

Report real vulnerabilities through the private process described in [`../SECURITY.md`](../SECURITY.md); never open a public issue containing credentials or production logs.
