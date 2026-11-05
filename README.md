<div align="center">

# Obsidian

Structured, secure logging foundations for the NOX ecosystem.

[![CI](https://github.com/mburakmmm/obsidian/actions/workflows/ci.yml/badge.svg)](https://github.com/mburakmmm/obsidian/actions/workflows/ci.yml)
[![Release](https://github.com/mburakmmm/obsidian/actions/workflows/release.yml/badge.svg)](https://github.com/mburakmmm/obsidian/actions/workflows/release.yml)
![Status](https://img.shields.io/badge/status-experimental-orange)
![NOX](https://img.shields.io/badge/NOX-2.0.143-6f42c1)

</div>

Obsidian is a small standalone logging library being built for Nyx, Aether, Nova, Feather, Atlas, Quartz, Rune, Chronos, Ember, VAULT, Pulse and Aura. Those projects may depend on Obsidian; Obsidian core never depends on them.

The project is experimental. The synchronous in-memory core is implemented and verified locally, but no stable package has been published. `AGENTS.md` is the engineering contract and `todo.md` contains the evidence-gated roadmap.

## Design priorities

1. Semantic correctness
2. Confidentiality
3. Reliability and explicit lifecycle
4. Portability and bounded resource use
5. Ergonomics and measured performance

Obsidian wraps and extends `nox.log`; it does not replace or fork the standard library. There is no hidden default logger, automatic telemetry or reverse dependency on a NOX framework.

## Current capabilities

- Numeric `TRACE` through `CRITICAL` levels plus the `OFF` threshold.
- Explicit logger, clock and sink instances.
- Caller-isolated structured record snapshots.
- Bounded drop-oldest memory sink with drop accounting.
- Stable sink registration and idempotent lifecycle.
- Pre-sink scalar field redaction and assignment masking.
- Deterministic LLVM and QBE tests.

Text/JSONL formatting, console/file sinks, the complete security matrix, context binding, rotation and conditional async dispatch remain gated future phases.

## Toolchain

| Component | Baseline |
|---|---|
| NOX compiler | `noxc 2.0.143` |
| NOX source | `a8940d27826849a526c3e918126ac6dd6ef571d1` |
| Obsidian package | `0.0.0`, unreleased |
| Verified locally | macOS arm64, LLVM and QBE |

See [`docs/compatibility.md`](docs/compatibility.md) before relying on a NOX capability or platform claim.

## Example

The API is internal and may change before the first release:

```nox
import fields
from clock import FakeClock
from fields import LogField
from level import INFO
from logger import Logger
from sinks.memory import MemorySink

clock: FakeClock = FakeClock(1700000000000)
log_instance: Logger = Logger("service.auth", INFO, clock)
memory: MemorySink = MemorySink("memory", 128)
log_instance.add_sink(memory)

event_fields: list[LogField] = [LogField("user_id", fields.string_value("u-123"))]
log_instance.info("login succeeded", event_fields)
```

Downstream packages use the dependency alias prefix, such as `from obsidian.logger import Logger`. Local repository code omits the prefix because NOX resolves first-party modules from the directory containing `nox.json`.

## Development

```sh
noxc check examples/memory_logging.nox
noxc run --backend llvm examples/memory_logging.nox
noxc run --backend qbe examples/memory_logging.nox
noxc test --backend llvm tests
noxc test --backend qbe tests
bash scripts/verify-package-import.sh
```

Compile-fail fixtures under `tests/compile_fail` must exit non-zero. Test files, assertions and skips are reported separately in CI.

## Repository map

```text
*.nox                    Small project-root library modules
sinks/                   Sink implementations
examples/                Compiling usage examples
tests/unit/              Behavioral tests
tests/compile_fail/      Explicit negative compiler fixtures
docs/                    Architecture, API, compatibility and ADRs
.github/workflows/       CI and gated release automation
```

NOX 2.0 resolves package modules from the repository root; a decorative Python-style `src/obsidian/__init__.nox` tree would not be importable under the pinned compiler.

## Security

Never place real credentials or production logs in an issue, test or example. Use synthetic sentinels. Read [`SECURITY.md`](SECURITY.md) before reporting a possible vulnerability.

The current sanitizer is a baseline, not the completed Phase 4 security surface. Do not describe this repository as production-ready until the release gates in `todo.md` pass.

## Releases and registry publication

Version tags run the full CI matrix, create a draft GitHub Release, execute `noxc publish` against noxpkg and publish the GitHub Release only after registry submission succeeds. The workflow also blocks mismatched versions, changelog omissions and missing redistribution licensing.

See [`docs/releasing.md`](docs/releasing.md) for the exact process and recovery rules.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), [`AGENTS.md`](AGENTS.md) and the current phase in [`todo.md`](todo.md). API changes require implementation, tests, documentation, examples and changelog updates in the same change.

## License

No redistribution license has been selected yet. The release workflow intentionally prevents publication until this is resolved.
