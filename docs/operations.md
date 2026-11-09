# Operations

Status: synchronous operation through Phase 10 path hardening; no durability, time rotation, shared-logger thread-safety or stderr claim.

## Dispatch mode

Only synchronous dispatch is supported. A `True` logger result means every selected route completed; `False` can mean global threshold rejection, redaction failure, filter failure or sink write failure. Per-sink threshold/filter rejection alone is not an infrastructure failure. Success does not imply stable-storage durability. There is no background queue, overflow policy or timeout-based async flush/close. Do not wrap logger calls in unjoined fire-and-forget tasks: their failures would be unobserved and logger shutdown could not prove completion. See ADR-0011.

Inspect `logger.diagnostics_snapshot()` for bounded sanitized failure counts. The default policy continues after a filter or sink failure. Flush and close also continue across sinks; close remains idempotent. Recursive log/flush/close calls from callbacks terminate and are counted. Route mutation or reconfiguration from a callback is rejected so the active traversal cannot grow or change underneath itself. Enable `raise_on_error` only when a caller explicitly wants a fixed `SinkError` category. Callback exception messages and record data are never copied into diagnostics.

## Logger construction and context lifecycle

Prefer `factory.build_logger` when constructing a logger from typed configs. It does not return a partially configured logger; a sink construction failure closes resources opened by that attempt and raises a sanitized category. Runtime `Logger.reconfigure` changes only name, threshold and redaction policy and never mutates the installed sink set.

Direct construction can call `add_sink_with_filter` for per-sink thresholds and exact logger filters. A logger accepts at most 64 active routes. Removing a route transfers lifecycle responsibility back to the caller; the logger no longer flushes or closes that sink. Typed factory routing is deferred on the pinned compiler. Exact names are case-sensitive; prefix/wildcard matching and sampling are not supported. Filters run after redaction on clones and are never called under an internal logging lock.

`Logger.bind` returns a context view that does not own sinks and therefore has no close operation. Close the parent logger exactly once. Pass a bound view explicitly to request-handling code; Obsidian does not read or install global/task-local request context.

## Console sink

Construct `ConsoleSink(name, CONSOLE_STDOUT, FORMAT_TEXT)` or select `FORMAT_JSON`. The target is mandatory. The pinned NOX API only exposes stdout, so `CONSOLE_STDERR` is a declared capability gap and raises `SinkError` during construction.

Each write is synchronous and adds exactly one newline through the selected formatter. `flush()` confirms that prior sink calls returned but cannot flush the process stdio buffer because NOX exposes no such primitive. `close()` is idempotent; write/flush after close raise a stable `SinkError`.

## File sink

`FileSink(name, allowed_root, relative_path, format_kind, create_parent)` opens one append-only handle. The allowed root must already exist and be a directory. `relative_path` must be portable and relative; `create_parent=True` creates missing directories one component at a time inside the canonical root.

The sink rejects control characters before calling path or secret-pattern helpers, then rejects lexical traversal, absolute paths, existing symlink escapes, non-file targets and missing parents without opt-in creation. Component confinement also fails closed for direct non-canonical `.`/`..` candidates. Use an application-owned root that untrusted users cannot modify. The pinned filesystem API cannot safely identify a dangling final symlink or prevent concurrent path replacement.

Every `write` is an unbuffered operating-system write according to `nox.fs`. `flush()` is therefore a logical no-op and is not `fsync`; neither it nor `close()` claims stable-storage durability. Plain `FileSink` storage remains unbounded; select `RotatingFileSink` for an explicit storage budget.

Open, validation and write failures surface as sanitized `SinkError` categories. Error messages do not include the configured path, record or secret-bearing field values.

## Rotating file sink

`RotatingFileSink` accepts the same root/path/format inputs plus `RotationPolicy(max_bytes, max_archives)`. Rotation is checked before each write using encoded UTF-8 byte length. Exact-boundary writes remain in the active file. Records larger than `max_bytes` are rejected without writing.

Owned archives are named `<basename>.00000001` and increase monotonically across restarts. Retention keeps the newest configured count and removes only validated older files matching the exact owned pattern. `retention_candidates` provides a non-mutating oldest-first dry run. With valid owned files, maximum storage is `max_bytes * (max_archives + 1)`.

Only one process may own an active rotating path. Use a trusted, application-owned directory; the pinned filesystem API cannot eliminate hostile concurrent replacement or dangling-symlink races. Time-based rotation is deferred. Recovery categories and operator actions are documented in `recovery.md`.

Use a dedicated log directory. The pinned `read_dir` API materializes all names at once; Obsidian refuses directories above 10,000 entries but cannot prevent the stdlib's initial list allocation.

For bounded lifecycle validation, run `bash scripts/run-file-stress.sh <llvm|qbe> full`. Each full run uses three fresh processes; each process appends 40,000 records and sends another 40,000 records through size rotation while reopening both sinks every 1,000 writes. The host watchdog fails a round after 120 seconds and checks exact JSONL, masking, archive order, storage budget and unexpected files. This is a development/release test, not an application runtime dependency or durability proof.

## Unsupported evidence

- stderr output: no public NOX API.
- console broken-pipe/write failure: `print` exposes no recoverable error channel.
- disk-full simulation: not executed in the current hermetic CI environment.
- race-free hostile-directory handling: requires a public no-follow/open-relative primitive or an approved native boundary.
- cross-process rotation, time-based rotation and durable sync: unsupported/deferred.
