<div align="center">

# Obsidian

Structured, secure logging foundations for the NOX ecosystem.

[![CI](https://github.com/mburakmmm/obsidian/actions/workflows/ci.yml/badge.svg)](https://github.com/mburakmmm/obsidian/actions/workflows/ci.yml)
[![Release](https://github.com/mburakmmm/obsidian/actions/workflows/release.yml/badge.svg)](https://github.com/mburakmmm/obsidian/actions/workflows/release.yml)
![Status](https://img.shields.io/badge/status-experimental-orange)
![NOX](https://img.shields.io/badge/NOX-2.0.143-6f42c1)

</div>

Obsidian is a small standalone logging library being built for Nyx, Aether, Nova, Feather, Atlas, Quartz, Rune, Chronos, Ember, VAULT, Pulse and Aura. Those projects may depend on Obsidian; Obsidian core never depends on them.

The project is experimental. The synchronous scalar logging core is under evidence-gated development and no stable package has been published. `AGENTS.md` is the engineering contract and `todo.md` contains the phase roadmap.

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
- Pre-sink, case-insensitive scalar redaction with default and application-specific keys.
- Header, bearer-token, URL-userinfo and credential-query masking with fail-closed drop accounting.
- Deterministic single-line text formatting with control-character escaping.
- Canonical JSONL with RFC 3339 timestamps and preserved scalar JSON types.
- Explicit stdout console sink and canonical-root-checked append-only file sink for trusted roots.
- Sanitized sink error categories and explicit idempotent I/O lifecycle.
- Deterministic LLVM and QBE tests.

Stderr is unavailable in the pinned NOX public API and remains explicitly disabled. Nested values, exception capture, context binding, rotation and conditional async dispatch remain gated future phases.

## Toolchain

| Component | Baseline |
|---|---|
| NOX compiler | `noxc 2.0.143` |
| NOX source | `a8940d27826849a526c3e918126ac6dd6ef571d1` |
| Obsidian package | `0.0.0`, unreleased |
| Verified locally | macOS arm64, LLVM and QBE |
| Verified in CI | macOS arm64, Linux x64/arm64; LLVM and QBE |

See [`docs/compatibility.md`](docs/compatibility.md) before relying on a NOX capability or platform claim.

## Example

The API is internal and may change before the first release:

```nox
import obsidian.fields
from obsidian.clock import FakeClock
from obsidian.fields import LogField
from obsidian.level import INFO
from obsidian.logger import Logger
from obsidian.sinks.memory import MemorySink

clock: FakeClock = FakeClock(1700000000000)
log_instance: Logger = Logger("service.auth", INFO, clock)
memory: MemorySink = MemorySink("memory", 128)
log_instance.add_sink(memory)

event_fields: list[LogField] = [LogField("user_id", obsidian.fields.string_value("u-123"))]
log_instance.info("login succeeded", event_fields)
```

Library, test and example imports use the package name `obsidian`. The pinned compiler resolves those self-imports correctly when Obsidian is loaded as a dependency, but not while compiling the package as the root project. Development therefore runs a hermetic downstream-consumer fixture; see ADR-0006.

## Development

```sh
bash scripts/run-package-suite.sh llvm
bash scripts/run-package-suite.sh qbe
bash scripts/verify-package-import.sh
```

Compile-fail fixtures under `tests/compile_fail` must exit non-zero. Test files, assertions and skips are reported separately in CI.

## Repository map

```text
*.nox                    Small project-root library modules
sinks/                   Sink implementations
examples/                Compiling usage examples
tests/unit/              Behavioral tests
tests/security/          Synthetic-sentinel and fail-closed acceptance tests
tests/compile_fail/      Explicit negative compiler fixtures
docs/                    Architecture, API, compatibility and ADRs
.github/workflows/       CI and gated release automation
```

NOX 2.0 resolves package modules from the repository root; a decorative Python-style `src/obsidian/__init__.nox` tree would not be importable under the pinned compiler.

## Security

Never place real credentials or production logs in an issue, test or example. Use synthetic sentinels. Read [`docs/security.md`](docs/security.md) for the redaction boundary and [`SECURITY.md`](SECURITY.md) before reporting a possible vulnerability.

Redaction is pattern- and policy-based; it cannot discover arbitrary secrets in prose. Do not describe this repository as production-ready until the release gates in `todo.md` pass.

## Releases and registry publication

Version tags run the full CI matrix, create a draft GitHub Release, execute `noxc publish` against noxpkg and publish the GitHub Release only after registry submission succeeds. The workflow also blocks mismatched versions, changelog omissions and missing redistribution licensing.

See [`docs/releasing.md`](docs/releasing.md) for the exact process and recovery rules.

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md), [`AGENTS.md`](AGENTS.md) and the current phase in [`todo.md`](todo.md). API changes require implementation, tests, documentation, examples and changelog updates in the same change.

## License

No redistribution license has been selected yet. The release workflow intentionally prevents publication until this is resolved.
