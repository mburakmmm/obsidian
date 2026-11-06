# Operations

Status: Phase 3 supported subset; no durability, rotation or stderr claim.

## Console sink

Construct `ConsoleSink(name, CONSOLE_STDOUT, FORMAT_TEXT)` or select `FORMAT_JSON`. The target is mandatory. The pinned NOX API only exposes stdout, so `CONSOLE_STDERR` is a declared capability gap and raises `SinkError` during construction.

Each write is synchronous and adds exactly one newline through the selected formatter. `flush()` confirms that prior sink calls returned but cannot flush the process stdio buffer because NOX exposes no such primitive. `close()` is idempotent; write/flush after close raise a stable `SinkError`.

## File sink

`FileSink(name, allowed_root, relative_path, format_kind, create_parent)` opens one append-only handle. The allowed root must already exist and be a directory. `relative_path` must be portable and relative; `create_parent=True` creates missing directories one component at a time inside the canonical root.

The sink rejects lexical traversal, absolute paths, existing symlink escapes, non-file targets and missing parents without opt-in creation. Use an application-owned root that untrusted users cannot modify. The pinned filesystem API cannot safely identify a dangling final symlink or prevent concurrent path replacement.

Every `write` is an unbuffered operating-system write according to `nox.fs`. `flush()` is therefore a logical no-op and is not `fsync`; neither it nor `close()` claims stable-storage durability. Storage is unbounded until the Phase 6 rotation/retention gate is implemented.

Open, validation and write failures surface as sanitized `SinkError` categories. Error messages do not include the configured path, record or secret-bearing field values.

## Unsupported evidence

- stderr output: no public NOX API.
- console broken-pipe/write failure: `print` exposes no recoverable error channel.
- disk-full simulation: not executed in the current hermetic CI environment.
- race-free hostile-directory handling: requires a public no-follow/open-relative primitive or an approved native boundary.
- cross-process rotation, retention and durable sync: deferred.
