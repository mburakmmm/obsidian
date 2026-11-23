# ADR-0021 — Release provenance strategy

The current release evidence binds the tag, source commit, CI results, downloaded SBOM digest and credential-free install. Consumers can use these checks for integrity and compatibility. A publisher signature or GitHub artifact attestation carries a separate identity and trust claim.

## GitHub artifacts

Prefer GitHub's OIDC-based attestations for generated release assets. Attest the exact CycloneDX file uploaded by the protected, tag-only release job after the CI matrix and SBOM checks. Pin the attestation action to a reviewed full commit SHA. Grant `id-token: write` and `attestations: write` only to that job when rollout is approved. Keep the existing repository credential model.

Before enabling the release gate, verify a new test asset with `gh attestation verify` against the expected repository and signer workflow. Check that a modified byte and a mismatched repository or workflow fail. Record the verified subject digest. An attestation over the SBOM proves provenance for that asset. Package source integrity still uses the immutable release ref and the downstream lock.

## Registry publisher identity

Use NOX's registry-bound signing only after an operator has chosen a key owner, offline backup, fingerprints for trust distribution, and a revocation contact. Record the signed ref and commit after publish and verify the consumer lock with `noxc sign check --require`. Rotate and test revocation before requiring signatures for consumers. Publisher keys and registry credentials stay in the operator environment.

The 1.1.0 release remains checksum-verified and unsigned. Activation is tracked separately from this strategy.

References: [GitHub artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations), [NOX package-tool signing](https://github.com/mburakmmm/nox-lang/blob/v2.2.38/docs/tools/noxc.md).
