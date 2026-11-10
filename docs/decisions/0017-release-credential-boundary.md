# ADR-0017: keep registry credentials outside release automation

- Status: accepted after the `v0.9.0-beta.1` release
- Date: 2026-11-10

## Context

The first beta tag passed the complete GitHub release matrix, but the tagged workflow then stopped at a registry-authentication step because no repository or environment token was configured. The project owner had explicitly requested that agents run `noxc publish` from the existing local session after commits and not add token handling to the repository. The tag and all test evidence remained valid; only the workflow's credential assumption was wrong.

GitHub Release publication and noxpkg submission have different trust boundaries. GitHub Actions already receives a scoped repository token for release creation, while the operator's noxpkg identity exists in a local credential store outside this repository. Synthesizing or copying those credentials into CI would expand secret exposure without improving the tested artifact.

## Decision

- The tag-triggered workflow owns the complete verification matrix, immutable-input validation and GitHub Release lifecycle only.
- The workflow never reads, writes or generates noxpkg credentials.
- Hyphenated SemVer tags are GitHub prereleases; stable tags may be marked latest only after the same matrix passes.
- `noxc publish github.com/mburakmmm/obsidian --ref <ref>` is an explicit operator action using the already authenticated local installation.
- Release evidence records GitHub matrix status and registry submission separately. A successful submission is not described as registry approval or downstream installability.
- Published tags are never retargeted to repair release automation. Workflow corrections apply to later tags.

## Consequences

Repository and Actions secret scope is smaller, and a missing registry secret cannot block a verified GitHub prerelease. Publication has one deliberate manual step and therefore requires exact command/result recording. The `v0.9.0-beta.1` workflow failure remains visible as historical evidence; the same immutable tag was submitted locally and published as a GitHub prerelease after all matrix jobs passed.
