# ADR-0019: promote the beta core unchanged as the stable candidate

- Status: accepted as a candidate; effective only at a verified `v1.0.0` release
- Date: 2026-11-11

## Context

The `v0.9.0-beta.1` public inventory and `obsidian.log.v1` schema passed the complete supported matrix and a clean public-registry installation. Phase 12 must decide whether stable promotion expands, removes or preserves that contract. Adding speculative APIs during the freeze would weaken the beta compatibility evidence and create unmeasured lifecycle or security risk.

The pinned NOX 2.1.0 compiler still lacks proven portable support for stderr, a bounded asynchronous record queue, durable `fsync`, safe cross-process rotation, recursive typed field values and the natural `Logger.trace` spelling. Optional ecosystem adapters are tied to exact external revisions.

## Decision

- The stable core candidate is exactly the core inventory in `docs/public-api.md`; no public symbol is added or removed during promotion.
- `obsidian.log.v1` is the stable schema candidate with the same required/optional fields, JSON kinds and additive-property rules.
- `trace_event` and `log(TRACE, ...)` remain the supported TRACE paths. No unproven alias is introduced for aesthetics.
- Nyx, Aether and Quartz adapters remain preview and do not receive the core stable compatibility guarantee.
- Explicitly absent capabilities remain absent from `v1.0.0`. They require later ADRs, executable tests and compatible versioning.
- The existing beta API contract test is renamed to `stable_api_test.nox` without duplicating assertions. The public-registry probe runs that same stable candidate against the published beta tag to prove upgrade compatibility.
- These decisions become a stable release promise only after the exact `v1.0.0` commit passes every Phase 12 gate and is published without retargeting its tag.

## Consequences

Beta consumers using the documented core need no source migration for the stable candidate. The release remains deliberately synchronous and scalar rather than expanding scope at the freeze boundary. Importable internal helpers and preview adapters can still evolve under their documented policies. Until `v1.0.0` is actually published, repository documentation must say stable candidate rather than stable release.
