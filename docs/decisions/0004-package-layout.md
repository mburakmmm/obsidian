# ADR-0004: project-root NOX modules

- Status: superseded by ADR-0006
- Date: 2026-11-05

## Context

The conceptual repository layout in `AGENTS.md` uses a Python-like `src/obsidian/__init__.nox` shape but explicitly requires adaptation to actual NOX package rules.

At NOX 2.0.143, first-party imports resolve `.nox` modules under the directory containing `nox.json`. Dependency imports use the alias as the first path segment and resolve the remaining path inside the dependency repository. No source-root manifest field or `__init__.nox` package facade is documented.

## Decision

Place library modules at repository root and sink modules under `sinks/`. The original Phase 0 decision used unqualified imports for local code and `obsidian.*` imports for consumers.

Phase 2's multi-module dependency probe showed that the local-import half of this decision does not produce a consumable package. ADR-0006 replaces the import and test execution details while retaining the project-root file layout.

## Consequences

- The repository will not create a decorative, unbuildable `src/obsidian` tree.
- Public documentation must show consumer imports separately from local test imports.
- This ADR must be revisited if a future pinned NOX release adds a verified source-root/package facade feature.
