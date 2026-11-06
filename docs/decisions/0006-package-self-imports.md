# ADR-0006: package self-imports and consumer-harness tests

- Status: accepted
- Date: 2026-11-06
- Supersedes: ADR-0004's local-import and root-test details

## Context

The Phase 0 dependency probe imported only `version.nox`, which has no internal imports. Phase 2 added a realistic dependency probe for `format_json.nox` and its transitive module graph. With unqualified internal imports such as `import fields`, NOX 2.0.143 and 2.0.181 searched the consumer project root and failed with `unknown alias, or project file not found`.

The pinned upstream package-resolution tests establish that a package refers to its own modules through the `name` in its own `nox.json`, independent of the alias chosen by a consumer. An `obsidian` package module must therefore import `obsidian.fields`, not `fields`.

The same compiler revisions do not resolve the root project's manifest name as a self alias. Consequently, correct package sources using `obsidian.*` cannot be compiled directly as root-project examples/tests.

## Decision

- Library modules use `obsidian.*` for every package-internal import.
- Tests and examples use the same public dependency paths as downstream consumers.
- `scripts/run-package-suite.sh` creates an isolated temporary Git package from the working tree, installs it into an isolated downstream project and runs the complete test/example suite there on the selected backend.
- `scripts/verify-package-import.sh` remains a smaller exact-output and lock-resolution probe for the formatter's transitive graph.
- Temporary `NOX_HOME`, package repositories and consumer projects are removed after each run.

## Consequences

- Tests exercise the actual installed-package resolution path instead of a different local-only import graph.
- Working-tree changes are captured in a temporary commit, so tests do not depend on a previously pushed revision.
- Direct commands such as `noxc test tests` from the Obsidian repository root are unsupported at the pinned compiler revision; use the harness.
- CI must keep the hermetic harness on every supported backend and platform.
- Revisit this decision if a future pinned compiler resolves a root project's manifest name as a self alias.
