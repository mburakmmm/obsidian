# Migration guide

Status: Phase 11 beta-candidate guidance; no beta tag has been issued.

## From `nox.log`

Obsidian wraps the standard logging semantics but does not replace `nox.log` or modify its module-level threshold. Create and own an explicit logger, clock and sink:

```nox
import obsidian.fields
from obsidian.clock import SystemClock
from obsidian.fields import LogField
from obsidian.level import INFO
from obsidian.logger import Logger
from obsidian.sinks.memory import MemorySink

logger: Logger = Logger("service.auth", INFO, SystemClock())
memory: MemorySink = MemorySink("recent", 128)
logger.add_sink(memory)
logger.info("login succeeded", [LogField("user_id", obsidian.fields.string_value("u-123"))])
logger.flush()
logger.close()
```

Map `nox.log.WARN` to Obsidian `WARNING`; Obsidian accepts `WARN` as an input alias but emits the canonical name `WARNING`. Replace implicit process-global context with `request_logger = logger.bind(...)` and pass that view explicitly. Convert mixed values to `LogField` plus one of the typed scalar constructors; arbitrary objects, nested containers and implicit stringification are rejected.

Choose stdout console, bounded memory, append-only file or size-rotating file deliberately. `flush` is not `fsync`, console stderr is unavailable on the pinned compiler and shared-logger thread safety is not claimed. Inspect `diagnostics_snapshot()` and close the owning logger. Removing a sink transfers close responsibility to the caller.

## From pre-beta Obsidian internals

Code written against the `0.0.0` development tree must move to the symbols in `public-api.md`. Direct imports from `field_keys`, `field_set`, `format_common`, internal rotation/path helpers, factory cleanup helpers or underscore-prefixed fields are not protected. Create `FieldValue` through the typed factory functions and treat snapshots as caller-owned copies.

The natural `Logger.trace` spelling is not available because the pinned LLVM backend produces a duplicate symbol; use `trace_event` or `log(TRACE, ...)`. Async/config-file/network/exception APIs were never shipped and have no migration aliases.

## JSON consumers

Require `schema_version == "obsidian.log.v1"`, read properties by name and ignore unknown top-level properties. Do not rely on JSON object order, although the current emitter is deterministic. Treat `request_id`, `trace_id` and `span_id` as optional. See `schema.md` for the required types and version-bump rules.

Before adopting a later Obsidian release, run the downstream contract against both supported backends and review the release's migration notes. Preview ecosystem adapters require their exact documented framework revision.

