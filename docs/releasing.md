# Release process

Obsidian releases are immutable tag-driven publications. GitHub Actions publishes a GitHub Release on a version tag, and the operator runs registry publication separately.

## Prerequisites

1. Confirm the repository's MIT license remains appropriate for the release.
2. Configure a protected GitHub Actions environment named `release`.
3. Require the CI checks for `main` and restrict who may approve the `release` environment.
4. Keep the release operator's existing noxpkg session outside the repository and GitHub Actions.

Do not copy a noxpkg token or generated credentials into the repository, workflow, GitHub secret configuration or release evidence. Package submission is an explicit operator action using an already authenticated local `noxc` installation.

## Preparing a version

1. Complete the applicable phase gate in `todo.md`.
2. Set the same exact version in `nox.json` and `version.nox`; the gate checks both.
3. Keep `nox.json`'s `source` declaration at `nox`; publishing scans the production tree and must fail if native source is introduced without an explicit design change.
4. Move relevant entries from `Unreleased` into `## [X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`.
5. Run `scripts/run-package-suite.sh` for LLVM and QBE, `scripts/run-async-capability-audit.sh`, the negative fixtures and the package import probe.
6. Commit the release preparation and wait for required CI checks.
7. Create an annotated tag that points at that exact commit and push it without ever retargeting it:

   ```sh
   git tag -a vX.Y.Z -m "Obsidian vX.Y.Z"
   git push origin vX.Y.Z
   ```

## Publication

The `Release` workflow:

1. Reuses the complete CI matrix at the tagged commit.
2. Verifies tag, manifest, changelog, license and clean checkout alignment.
3. Creates a draft GitHub Release.
4. Attaches a CycloneDX 1.5 package SBOM from checksum-verified NOX 2.2.70. The generator verifies identical compiler output across two invocations and adds the validated manifest version when the compiler omits it.
5. Publishes stable tags as latest releases and hyphenated tags as prereleases.

After the exact tag passes the matrix, submit it from the trusted local operator session:

```sh
bash scripts/publish-package.sh vX.Y.Z
```

The wrapper keeps the public description, search tags and `source: nox` declaration consistent. The registry may display the submitted ref as the package version. For routine commits, point the operator submission at the latest verified release tag to keep the public version stable. The existing local `noxc` installation handles authentication and optional attestation.

Registry submission is not proof of public-index visibility or downstream installability. With the exact pinned compiler, verify the public name, tag and peeled commit from an isolated consumer:

```sh
OBSIDIAN_VERIFY_REGISTRY_METADATA=1 \
  NOX_RESOURCE_DIR=/path/to/pinned-release \
  NOXC=/path/to/pinned-release/bin/noxc \
  bash scripts/verify-registry-install.sh \
  vX.Y.Z X.Y.Z <expected-full-commit> <expected-noxc-version>
```

Only record registry availability after this probe succeeds on LLVM and QBE. The repository never stores or synthesizes registry credentials.

See [ADR-0021](decisions/0021-release-provenance.md) for the separate GitHub artifact attestation and registry publisher signing rollout criteria.

## Failure recovery

- Before the draft exists: fix the release commit and create a new version/tag. Never move a published tag.
- Draft exists but final GitHub publication failed: rerun the workflow; verify the existing draft before manual intervention.
- Local registry submission fails: do not alter the tag or add credentials to CI; record the registry state separately and retry only from the trusted operator environment.
- Public GitHub Release exists but noxpkg is not approved: leave an explicit note; do not claim registry availability.
