# v1.0.0 stable readiness

Status: Phase 12 in progress. No `v1.0.0` tag, stable GitHub Release or stable registry ref exists.

## Promotion baseline

The candidate stable surface is the synchronous core protected by `v0.9.0-beta.1` and `docs/public-api.md`. `obsidian.log.v1` remains the candidate stable JSON schema. Preview Nyx, Aether and Quartz adapters are not promoted by the core stable release unless separately documented.

Stable promotion does not add async dispatch, stderr, recursive structured values, cross-process rotation, exception stacks, network sinks or tracing. Their documented absence is preferable to speculative or unproven APIs.

## Registry readiness evidence

On 2026-11-10, the checksum-verified NOX 2.1.0 macOS ARM64 release executed:

```sh
NOX_RESOURCE_DIR=/path/to/nox-2.1.0-release \
  NOXC=/path/to/nox-2.1.0-release/bin/noxc \
  bash scripts/verify-registry-install.sh \
  v0.9.0-beta.1 \
  0.9.0-beta.1 \
  c2379fe493b8eb431220f8a5c2b1bd12b13f1867 \
  2.1.0
```

The public noxpkg index resolved `obsidian` to `github.com/mburakmmm/obsidian`; `nox.lock` resolved the immutable beta tag to the expected commit. In an isolated credential-free `NOX_HOME`, LLVM and QBE passed the protected API contract, schema-v1 contract, exact import output and exact version output. No security sentinel appeared in captured output.

This closes the public-index visibility and pinned-compiler clean-install prerequisite. It does not prove the future stable ref, stable release artifact, signatures, or exact stable-commit benchmarks.

## Remaining stable blockers

1. Freeze the core public inventory as stable and keep preview adapters explicitly outside that promise.
2. Prepare one aligned `1.0.0` manifest/source/changelog/release-note commit.
3. Run the complete supported platform/backend matrix, examples, security scans, benchmark harness and bounded stress at that exact commit.
4. Decide and verify signing/provenance only if working infrastructure exists; otherwise document it as unavailable without claiming it.
5. Create one immutable annotated `v1.0.0` tag only after the pre-publication gates pass.
6. Submit that exact tag with the external operator session, then rerun the public-index install probe against the stable tag and peeled commit.
7. Verify the public GitHub Release, registry resolution and documented evidence all identify the same commit before closing Phase 12.
