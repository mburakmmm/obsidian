# ADR-0016: beta API and schema compatibility policy

- Status: accepted for the Phase 11 beta candidate
- Date: 2026-11-10

## Context

Obsidian has executable synchronous behavior through Phase 10, but the repository previously described every non-level symbol as internal. Consumers need a finite supported surface and machine-output compatibility rules before any beta tag can be prepared. NOX packages expose module symbols directly, so documentation and downstream compile tests are the available stability boundary; an undocumented symbol cannot be made physically inaccessible by the pinned module system.

## Decision

- `docs/public-api.md` is the normative beta API inventory. Only listed symbols receive compatibility protection.
- Core symbols are marked **beta**. Optional Nyx/Aether/Quartz adapters remain **preview** and are pinned to exact tested consumer revisions.
- Undocumented module symbols, underscore-prefixed state and test injection hooks are **internal** even when NOX permits importing or mutating them.
- Before `1.0.0`, a breaking beta API change requires a documented minor release, migration instructions and updated downstream contract tests. Patch releases may add compatible APIs and fix behavior without removing documented symbols.
- At and after `1.0.0`, documented public API removal, signature changes or incompatible semantics require a new major version.
- JSONL schema identity is independent of package SemVer. The current emitter uses `obsidian.log.v1`; incompatible required-field, type or meaning changes require a new schema identifier.
- Within schema v1, consumers must locate properties by name and ignore unknown properties. The emitter keeps deterministic order, but object order is not a consumer parsing contract.
- Required v1 properties cannot be removed or change JSON kind. Correlation identifiers remain optional and omission is distinct from an empty emitted value.
- A downstream beta API compile/runtime contract and a schema-v1 consumer contract run on LLVM and QBE.

## Consequences

The repository can evaluate compatibility mechanically without claiming that every importable helper is stable. Existing pre-beta users of undocumented symbols must migrate to the listed surface. The manifest remains `0.0.0` until a redistribution license, beta version, changelog section and tag are approved together; this ADR does not authorize a release by itself.

