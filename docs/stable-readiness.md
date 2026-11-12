# v1.0.0 stable readiness

Status: complete. `v1.0.0` was published from immutable commit `e787ab6d8f6232ed9951e672cf38a88060e4cb0c`; the stable GitHub Release, annotated tag, changelog and public registry ref are aligned.

## Promotion baseline

The candidate stable surface is the synchronous core protected by `v0.9.0-beta.1` and `docs/public-api.md`. ADR-0019 freezes that inventory unchanged for the stable candidate. `obsidian.log.v1` remains the candidate stable JSON schema. Preview Nyx, Aether and Quartz adapters are not promoted by the core stable release unless separately documented.

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

This closed the public-index visibility and pinned-compiler clean-install prerequisite before tagging. It did not by itself prove the later stable ref, release artifact, signatures or exact stable-commit benchmarks; those are covered by the release evidence below.

## Readiness and release evidence

Commit `c0dbaf2244d8430a5f25cb721b8c0ac2540c9ba1` and CI `42834838904` passed on macOS ARM64, Linux x64 and Linux ARM64. Every job ran LLVM and QBE with 22 behavioral files/467 assertions/0 skips, three expected compile-fail fixtures, seven async capability probes, dependency/import checks, three pinned ecosystem probes/36 checks, all examples, benchmark smoke and 8,000-event file/rotation stress smoke. This validates the registry-readiness harness and isolated capability audit; it is not the future `v1.0.0` release commit.

ADR-0019 and `stable_api_test.nox` now define the unchanged stable core candidate. The same test is run against the public beta tag by the registry gate, so stable-candidate source usage remains compatible with the released beta checkout.

Commit `ccc9e411ca8dc5087f8fcc12b017d16b481c50d6` and CI `42968550569` then passed the stable-candidate rename and policy on the same three-platform LLVM/QBE matrix with unchanged totals: 22 behavioral files/467 assertions/0 skips per backend, plus every compile-fail, capability, dependency, adapter, example, benchmark-smoke and file-stress gate. The public registry probe also ran `stable_api_test.nox` successfully against immutable beta commit `c2379fe493b8eb431220f8a5c2b1bd12b13f1867` on both backends.

The aligned release commit `e787ab6d8f6232ed9951e672cf38a88060e4cb0c` passed main CI `42971160582`, then annotated tag `v1.0.0` passed release CI `42971769840` on macOS ARM64, Linux x64 and Linux ARM64. Every job ran LLVM and QBE with 22 behavioral files/467 assertions/0 skips per backend, the three compile-fail fixtures, seven capability probes, dependency/import checks, three pinned ecosystem probes/36 checks, all examples, benchmark smoke and bounded file/rotation stress smoke.

The clean exact-commit local benchmark and full stress harnesses passed on LLVM and QBE with `dirty=false`. Full stress processed 120,000 events per path/backend and retained exactly four owned archives within 19,600 bytes. The external operator session published `v1.0.0` without adding credentials to the repository or GitHub Actions. The public registry gate then resolved `v1.0.0` to exact `e787ab6d8f6232ed9951e672cf38a88060e4cb0c`, reported package version `1.0.0`, and passed API/schema/import/version contracts on LLVM and QBE under checksum-verified NOX 2.1.0.

## Provenance assessment

The release workstation had no configured `user.signingkey`, `tag.gpgSign` or `commit.gpgSign`, and the GitHub Release workflow did not emit an artifact attestation. `v1.0.0` is therefore an immutable annotated but unsigned tag with exact workflow/lock evidence; no signed-provenance claim is made.

## Gate outcome

All applicable stable blockers are closed. Unsupported features and platforms remain documented limitations, not silently skipped evidence. Phase 12 is complete.
