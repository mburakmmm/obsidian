# ADR-0018: stable release evidence must bind to one immutable commit

- Status: accepted for Phase 12
- Date: 2026-11-10

## Context

The `v0.9.0-beta.1` tag proves the synchronous beta surface on the supported compiler, backend and platform matrix. A stable `v1.0.0` claim is stronger: source, public API, schema, benchmark report, changelog, registry resolution, GitHub artifact and immutable tag must all identify the same release. A successful registry submission alone is insufficient because noxpkg publishes metadata and consumers fetch code from the repository.

The operator keeps registry credentials outside GitHub Actions under ADR-0017. Stable verification therefore needs a reproducible downstream probe that uses only the public index and an isolated `NOX_HOME`, without copying the working tree into the consumer as a dependency.

## Decision

- `scripts/verify-registry-install.sh` is the post-publication registry gate. It resolves the package by the public name `obsidian`, pins the requested tag, and rejects an unexpected repository or resolved commit.
- The probe uses the exact release compiler binary, an empty isolated `NOX_HOME`, and no credentials.
- Both LLVM and QBE must run the protected public API contract, schema-v1 consumer contract, exact package-import output and exact version output from the registry-resolved checkout.
- Captured test output is scanned for security sentinels. A failure that contains a sentinel is replaced by a fixed diagnostic.
- Phase 12 does not promote the beta contract to stable until the exact proposed `v1.0.0` commit passes the full matrix, examples, benchmark/stress gates and release-input alignment.
- The stable tag is created only after those pre-publication gates. After local registry submission, the public-index probe must resolve that same immutable tag and commit before the Phase 12 gate closes.
- Signature or provenance claims remain disabled unless the exact release artifact is actually signed or attested and independently verified.

## Consequences

Registry discovery, tag immutability and compiler compatibility become executable evidence rather than release-note assertions. Stable publication retains a deliberate post-tag operator step, so a failed registry probe cannot be repaired by moving the tag; it requires correcting external publication state or issuing a new version. The beta registry probe is useful readiness evidence but does not by itself authorize a stable version bump.
