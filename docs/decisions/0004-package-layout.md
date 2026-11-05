# ADR-0004: project-root NOX modules

- Status: accepted for Phase 0
- Date: 2026-11-05

## Context

The conceptual repository layout in `AGENTS.md` uses a Python-like `src/obsidian/__init__.nox` shape but explicitly requires adaptation to actual NOX package rules.

At NOX 2.0.143, first-party imports resolve `.nox` modules under the directory containing `nox.json`. Dependency imports use the alias as the first path segment and resolve the remaining path inside the dependency repository. No source-root manifest field or `__init__.nox` package facade is documented.

## Decision

Place library modules at repository root and sink modules under `sinks/`. Local code imports `logger` or `sinks.memory`; a consumer whose dependency alias is `obsidian` imports `obsidian.logger` or `obsidian.sinks.memory`.

Tests live under `tests/` but are run from repository root so the same `nox.json` is found. Negative compile fixtures do not use the `*_test.nox` suffix because `noxc test` treats compilation failure as a failed suite.

## Consequences

- The repository will not create a decorative, unbuildable `src/obsidian` tree.
- Public documentation must show consumer imports separately from local test imports.
- This ADR must be revisited if a future pinned NOX release adds a verified source-root/package facade feature.
