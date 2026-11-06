# ADR-0007: synchronous console and append-only file sinks

- Status: accepted for the supported Phase 3 subset
- Date: 2026-11-06

## Context

Obsidian needs synchronous console and file output without inventing APIs absent from NOX. At the pinned 2.0.143 revision, `print` writes only to stdout and exposes no stdio flush or failure channel; `print(file=...)` is explicitly unsupported. The same remains true in the observed 2.0.181 documentation. `nox.fs.FileWriter.write` is unbuffered, `open_append` owns an explicit handle and `close` is idempotent. There is no public `fsync`, `openat`/`O_NOFOLLOW`, `lstat` or recursive directory-creation API.

## Decision

- `ConsoleSink` requires an explicit target and format. `CONSOLE_STDOUT` is supported. `CONSOLE_STDERR` fails construction with a stable sanitized `SinkError`; no native shim or private runtime symbol is introduced.
- Console writes are synchronous `print(..., end="")` calls. `flush()` is a documented logical no-op because NOX exposes no stdio flush primitive.
- `FileSink` accepts an existing allowed root, a relative portable path, a format and an explicit `create_parent` flag.
- File output uses `nox.fs.open_append`; every record is encoded before one unbuffered `FileWriter.write` call. `close()` is explicit and idempotent.
- Relative paths reject absolute paths, traversal components, control characters, backslashes, drive separators and trailing separators. Every existing/created parent is canonicalized and constrained to the canonical allowed root by exact component-prefix comparison. Existing file symlinks are canonicalized and checked before opening. `nox.path.strip_prefix` is not used because the pinned revision fails a sibling-prefix boundary regression.
- Filesystem and path errors are translated to stable `SinkError` categories that never echo the configured path or record contents.
- File storage remains unbounded in Phase 3. Rotation, retention and durable `fsync` claims remain out of scope.

## Consequences

- Stdout and append-only file output are portable across the tested hosted LLVM/QBE targets without native glue.
- Stderr remains unsupported until a public NOX API exists or a separately approved cross-platform native boundary is designed.
- A trusted, application-owned allowed root is required. The public API cannot distinguish a missing file from a dangling final-component symlink and cannot make a race-free `openat(..., O_NOFOLLOW)` operation; an attacker who can mutate the log directory concurrently is outside this phase's proven boundary.
- Console broken-pipe/write failure cannot be observed through the documented `print` API. File open/write failures remain observable as sanitized `SinkError` values.
