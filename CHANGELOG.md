# Changelog

All notable changes will be recorded here. Versions follow Semantic Versioning once a public API is released.

## [Unreleased]

### Added

- Phase 0 repository scaffold and evidence-based roadmap.
- Pinned NOX 2.0.143 compatibility baseline.
- Minimal module, example and test used to verify package resolution on LLVM and QBE.
- Reproducible downstream dependency-alias import probe with exact lock resolution.
- Initial numeric level model with canonical names, `WARN` alias handling and fail-closed threshold checks.
- Tagged scalar field values and caller-isolated log record snapshots with reserved-key validation.
- Explicit clock injection, bounded memory sink and synchronous multi-sink logger with baseline pre-sink redaction and recursion rejection.
- Deterministic end-to-end memory logging example with a synthetic secret proving pre-sink masking.
- Cross-platform LLVM/QBE CI, professional repository templates and a gated tag-driven release workflow.
- Automated noxpkg submission with `noxc publish` after release preflight and the complete CI matrix succeed.

### Security

- No logging API or output sink is exposed yet.
