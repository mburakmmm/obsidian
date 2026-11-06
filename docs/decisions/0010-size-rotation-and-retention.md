# ADR-0010: Single-process size rotation and deterministic retention

- Status: accepted for the Phase 6 candidate
- Date: 2026-11-06

## Context

An append-only file sink is operationally unbounded. The pinned NOX filesystem API provides byte-size metadata, append handles, rename, directory listing and file removal, but no cross-process lock, no `lstat`, no no-follow open and no durable `fsync`. Directory listing is returned as an in-memory list in unspecified order.

## Decision

`RotatingFileSink` is a separate sink with explicit `RotationPolicy(max_bytes, max_archives)`. It is single-process only. Encoded UTF-8 byte length includes the output newline and is checked before each write. A write that would exceed the limit rotates the non-empty active file first; an event larger than the entire active-file limit is rejected without writing. A file exactly at the boundary is valid.

Archives remain in the active file's directory and use `<basename>.NNNNNNNN`, beginning at `00000001`. The fixed-width suffix gives deterministic lexical age ordering. Restart scans valid owned archives and continues after the greatest sequence. Sequence exhaustion is an explicit error.

Retention recognizes only the exact basename prefix plus eight non-zero decimal digits. Candidate names are sorted, and only the oldest excess owned archives are selected. `retention_candidates` is the dry-run API. Before deletion, every candidate must be a regular file, canonicalize to its literal expected path and remain under the canonical allowed root. Unrelated names are ignored. Matching directories, symlinks, oversized archives and validation failures stop retention with a sanitized error. Constructor discovery is non-destructive; restart excess is removed before the first event write so a later failure in multi-sink factory construction cannot delete archives from an otherwise unactivated logger.

Rotation closes the active handle before rename. If rename fails, the active path is reopened and the failure is reported without echoing paths or record data. If opening the new active file fails after rename, Obsidian attempts to rename the archive back and reopen it. An unrecoverable failure closes the sink and reports a fixed recovery category. Retention failure leaves the new active handle open but blocks later writes until retention succeeds.

Time-based rotation is deferred. Although the pinned API exposes wall-clock and modification milliseconds, a production policy still needs explicit clock injection, rollback handling, restart boundary semantics and UTC naming tests. Size-based rotation is sufficient to establish the Phase 6 bounded-storage gate without making those semantics up.

## Consequences

- With valid Obsidian-owned files, storage is bounded by `max_bytes * (max_archives + 1)`.
- Preexisting active or archive files larger than `max_bytes` are rejected instead of silently violating the budget.
- There is no cross-process collision guarantee. A second process using the same path is unsupported.
- A trusted application-owned directory remains mandatory. Without `lstat`/no-follow operations, hostile concurrent replacement and dangling-symlink races cannot be eliminated.
- The pinned `read_dir` API materializes a directory before Obsidian can inspect it. Obsidian refuses to process more than 10,000 entries, but operators must still use a dedicated log directory to bound the stdlib listing allocation.
- Rename is not advertised as durable persistence; `flush` remains logical and no `fsync` claim is made.
