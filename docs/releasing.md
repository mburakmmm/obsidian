# Release process

Obsidian releases are immutable tag-driven publications. A normal branch push never publishes a package.

## Prerequisites

1. Select and review a redistribution license. The release gate rejects the current pre-release placeholder license.
2. Configure a protected GitHub Actions environment named `release`.
3. Add the noxpkg API token created by `noxc login` as the environment secret `NOXPKG_TOKEN`.
4. Require the CI checks for `main` and restrict who may approve the `release` environment.

The secret is the registry token stored in `$NOX_HOME/credentials`, not a GitHub personal access token. It must never be printed, committed or copied into repository configuration.

## Preparing a version

1. Complete the applicable phase gate in `todo.md`.
2. Set the same exact version in `nox.json` and `version.nox`; the gate checks both.
3. Move relevant entries from `Unreleased` into `## [X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`.
4. Run both backend test suites, negative fixtures and the package import probe.
5. Commit the release preparation and wait for required CI checks.
6. Create an annotated tag that points at that exact commit and push it without ever retargeting it:

   ```sh
   git tag -a vX.Y.Z -m "Obsidian vX.Y.Z"
   git push origin vX.Y.Z
   ```

## Automated publication

The `Release` workflow:

1. Reuses the complete CI matrix at the tagged commit.
2. Verifies tag, manifest, changelog, license and clean checkout alignment.
3. Downloads the pinned NOX compiler and verifies the release checksum.
4. Validates the noxpkg identity with `noxc whoami`.
5. Creates a draft GitHub Release.
6. Executes `noxc publish github.com/mburakmmm/obsidian --ref vX.Y.Z`.
7. Makes the GitHub Release public only after registry submission succeeds.

Registry submission is not proof of moderator approval. After the workflow succeeds, verify the version from a clean downstream project and confirm its status in noxpkg before updating the release evidence.

## Failure recovery

- Before the draft exists: fix the release commit and create a new version/tag. Never move a published tag.
- Draft exists but registry submission failed: keep the release draft, fix credentials/service state and rerun the failed job.
- Registry submission succeeded but final publication failed: rerun the workflow; verify the existing draft before manual intervention.
- Public GitHub Release exists but noxpkg is not approved: leave an explicit note; do not claim registry availability.
