# Configuration

Status: published beta configuration contract and unchanged `v1.0.0` stable candidate; public symbols are limited to the normative inventory in `public-api.md`.

Obsidian configuration is explicit and typed. It never searches `.env`, a home directory, the working tree or a network location.

## Logger and redaction

```nox
from obsidian.config import LoggerConfig, RedactionConfig
from obsidian.level import INFO

redaction: RedactionConfig = RedactionConfig(["client_pin"])
config: LoggerConfig = LoggerConfig("service.auth", INFO, redaction)
```

Constructors validate before a logger is changed and copy caller-owned key lists. Error categories are fixed and do not include rejected values.

`LoggerConfig(..., raise_on_error=False)` defaults to bounded non-raising diagnostics. Explicit strict mode raises only fixed sanitized categories. `logger.reconfigure(config)` atomically replaces the logger name, threshold, redactor and error policy from the caller's synchronous perspective. It does not add, remove, close or replace sinks. A config that fails construction cannot be passed to `reconfigure`, so the existing logger remains usable.

## Sink factory

Use `memory_sink_config`, `console_sink_config`, `file_sink_config` or `rotating_file_sink_config` to create a typed `SinkConfig`, then pass the list to `factory.build_logger(config, sink_configs, clock)`. The rotating form additionally requires `max_bytes` and `max_archives`. At most 64 sink configs are accepted; a larger list is rejected before any sink resource is constructed. The factory constructs every accepted sink before returning the logger. If one construction fails, it closes sinks already constructed during that attempt and raises `SinkError("logger factory sink construction failed")` without echoing paths or values. A cleanup failure is separately observable as the fixed `logger factory cleanup failed` category.

`FormatterConfig(FORMAT_TEXT)` and `FormatterConfig(FORMAT_JSON)` are supported. Console configuration accepts only the pinned compiler's supported stdout target. File configuration remains subject to the trusted-root restrictions in `operations.md`.

The pinned compiler could not safely represent a typed route wrapper in optimized tests, so factory-built sinks use allow-all routing. Configure per-sink thresholds and filters explicitly with `logger.add_sink_with_filter` when constructing a logger programmatically. No partially working typed route config is exposed.

## Explicit environment override

```nox
import obsidian.config

effective: LoggerConfig = obsidian.config.with_threshold_environment(config, "OBSIDIAN_LEVEL")
```

Only the caller-named variable is read. Its value must be an exact supported level name. A missing variable returns a cloned equivalent config; an invalid value raises the fixed `environment threshold is invalid` category. The value is never included in the exception.

## Deliberately unavailable

- implicit environment or file discovery;
- JSON/TOML/YAML loaders;
- runtime sink-set replacement;
- `QueueConfig`, because Phase 7 concluded that the pinned toolchain cannot meet the portable queue and lifecycle contract;
- configuration values containing credentials or remote sink endpoints.
