# File rotation recovery

Status: published single-process size-rotation behavior and unchanged `v1.0.0` stable candidate; cross-process recovery remains unsupported.

## Normal restart

On construction, `RotatingFileSink` validates the active file and every owned archive. It reads the greatest eight-digit archive sequence and continues from the next value. Existing retention excess is marked pending and removed before the first event can be written; this avoids destructive retention side effects if a multi-sink factory later fails. A preexisting active or archive file larger than the configured byte limit is rejected so the configured storage budget is never claimed falsely.

## Observable failures

| Category | Meaning | Operator action |
|---|---|---|
| `file rotation rename failed` | The active file could not be renamed; Obsidian reopened it successfully | Inspect directory permissions/ownership; the old active content remains at the active path |
| `file rotation reopen failed` | Rename succeeded, new active open failed, and Obsidian restored/reopened the old active path | Inspect capacity and permissions before retrying |
| `file rotation recovery failed` | Obsidian could not restore a usable active handle | Treat the sink as closed; preserve both active/archive paths and repair manually |
| `rotation retention failed` | Rotation completed but retention did not | Repair the owned archive entry/permissions; later writes remain blocked until retention succeeds |
| `rotation archive collision` | The next deterministic archive name unexpectedly exists | Verify no second process owns the path and inspect external file creation |
| `rotation archive sequence is exhausted` | `99999999` has already been reached | Stop and migrate logs to a new basename under operator control |

All categories are fixed strings. They do not include configured paths, archive names, messages or record fields.

## Safety rules

- Never point two processes at the same active path.
- Keep the configured directory application-owned and inaccessible to untrusted writers.
- Use `retention_candidates(...)` to inspect the exact oldest-first deletion set without deleting anything.
- Do not rename unrelated files to the owned `<basename>.NNNNNNNN` pattern.
- Do not interpret logical `flush()` or successful rename as stable-storage durability.
- If an archive or active file is oversized, move it manually to a separately secured location before restarting; Obsidian will not silently truncate it.
