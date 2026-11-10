# Release process

Obsidian releases are immutable tag-driven publications. A normal branch push never publishes a package.

## Prerequisites

1. Confirm the repository's MIT license remains appropriate for the release.
2. Configure a protected GitHub Actions environment named `release`.
3. Require the CI checks for `main` and restrict who may approve the `release` environment.
4. Keep the release operator's existing noxpkg session outside the repository and GitHub Actions.

Do not copy a noxpkg token or generated credentials into the repository, workflow, GitHub secret configuration or release evidence. Package submission is an explicit operator action using an already authenticated local `noxc` installation.

## Preparing a version

1. Complete the applicable phase gate in `todo.md`.
2. Set the same exact version in `nox.json` and `version.nox`; the gate checks both.
3. Move relevant entries from `Unreleased` into `## [X.Y.Z] - YYYY-MM-DD` in `CHANGELOG.md`.
4. Run `scripts/run-package-suite.sh` for LLVM and QBE, `scripts/run-async-capability-audit.sh`, the negative fixtures and the package import probe.
5. Commit the release preparation and wait for required CI checks.
6. Create an annotated tag that points at that exact commit and push it without ever retargeting it:

   ```sh
   git tag -a vX.Y.Z -m "Obsidian vX.Y.Z"
   git push origin vX.Y.Z
   ```

## Publication

The `Release` workflow:

1. Reuses the complete CI matrix at the tagged commit.
2. Verifies tag, manifest, changelog, license and clean checkout alignment.
3. Creates a draft GitHub Release.
4. Marks hyphenated versions such as `v0.9.0-beta.1` as prereleases.
5. Publishes stable tags as latest releases and prerelease tags without the latest marker.

After the exact tag passes the matrix, submit it from the trusted local operator session:

```sh
noxc publish github.com/mburakmmm/obsidian --ref vX.Y.Z
```

Registry submission is not proof of moderator approval or downstream installability. Verify its reported status separately before updating release evidence. The repository never stores or synthesizes registry credentials.

## Failure recovery

- Before the draft exists: fix the release commit and create a new version/tag. Never move a published tag.
- Draft exists but final GitHub publication failed: rerun the workflow; verify the existing draft before manual intervention.
- Local registry submission fails: do not alter the tag or add credentials to CI; record the registry state separately and retry only from the trusted operator environment.
- Public GitHub Release exists but noxpkg is not approved: leave an explicit note; do not claim registry availability.
