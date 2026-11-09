# Changelog

All notable changes will be recorded here. Versions follow Semantic Versioning once a public API is released.

## [Unreleased]

### Added

- Phase 0 repository scaffold and evidence-based roadmap.
- Pinned and audited NOX compatibility baseline.
- Minimal module, example and test used to verify package resolution on LLVM and QBE.
- Reproducible downstream dependency-alias import probe with exact lock resolution.
- Initial numeric level model with canonical names, `WARN` alias handling and fail-closed threshold checks.
- Tagged scalar field values and caller-isolated log record snapshots with reserved-key validation.
- Explicit clock injection, bounded memory sink and synchronous multi-sink logger with baseline pre-sink redaction and recursion rejection.
- Deterministic end-to-end memory logging example with a synthetic secret proving pre-sink masking.
- Cross-platform LLVM/QBE CI, professional repository templates and a gated tag-driven release workflow.
- Automated noxpkg submission with `noxc publish` after release preflight and the complete CI matrix succeed.
- Canonical RFC 3339 text and JSONL formatters with stable field ordering, scalar type preservation and exact golden fixtures.
- Bounded record messages/string fields, bounded field counts, duplicate-key rejection and fail-closed non-finite float validation.
- Hermetic downstream-package test harness covering the complete suite and examples on LLVM and QBE.
- Explicit stdout console sink with deterministic text/JSON encoding and idempotent lifecycle.
- Append-only file sink with opt-in parent creation, canonical-root checks for trusted roots and sanitized error categories.
- Real filesystem integration coverage for append/reopen, UTF-8 byte size, permissions, traversal and existing symlink escapes.
- Case-insensitive redaction policy with validated application-specific sensitive keys.
- HTTP header, bearer-token, URL-userinfo, query credential and quoted assignment masking.
- Fail-closed logger redaction with dropped-event accounting and security acceptance coverage across memory, custom, console and file sinks.
- Immutable explicit context views with nested binding, event-field precedence and bounded request/trace/span identifiers.
- Typed logger, redaction, formatter and sink configuration with an all-or-nothing synchronous factory.
- Explicit threshold environment override with missing-variable handling and sanitized invalid-value errors.
- Overlapping-task context isolation coverage on LLVM and cooperative QBE.
- Single-process size-based rotating file sink with deterministic fixed-width archive names.
- Oldest-first dry-run retention selection, bounded archive count and restart sequence recovery.
- Sanitized rename/reopen recovery paths and strict owned-archive regular-file validation.
- Executable async capability probes for record transfer, non-blocking queue operations, worker lifecycle and genuine overlap.
- Exact logger filters and per-sink numeric thresholds through explicit route registration.
- Saturating sanitized diagnostics for redaction, filter, sink lifecycle and recursion failures.
- Framework-neutral safe HTTP completion metadata normalization.
- Optional Nyx v0.24.0 request lifecycle adapter with task-local monotonic duration and validated request IDs.
- Optional Aether v0.9.0 interceptor with request-scoped timing and explicit sanitized route names.
- Optional Quartz v0.9.15 bounded capture/assertion adapter for test projects.
- Isolated LLVM/QBE ecosystem probes, compiling integration examples and a core dependency-direction audit.
- Reproducible Phase 10 benchmark harness for disabled DEBUG, equivalent `nox.log` baseline, JSONL encoding and logger construction/close.
- Benchmark environment/schema documentation with fixed warm-up, sample, variance and dirty-tree reporting.
- Initial clean-commit macOS arm64 LLVM/QBE observation with explicit timer-quantization and non-guarantee caveats.
- Redirected stdout INFO benchmark with exact output accounting and synthetic-secret leak detection.
- Maximum-length Unicode JSONL workload reporting encoded bytes per event.
- Clean-commit macOS arm64 observations for redirected console and maximum-length Unicode JSONL workloads.
- Temporary-root JSONL file throughput and forced size-rotation pause workloads with exact output, retention and sentinel checks.
- Clean-commit macOS arm64 observations for JSONL file append and forced size rotation.
- Prebuilt empty-process and Logger-process startup workloads with silent-exit validation and host Python version reporting.
- Clean-commit macOS arm64 observations for LLVM/QBE empty and Logger process startup.
- Seven-process peak-RSS workloads for empty runtime, bounded MemorySink, repeated sink failures and deterministic slow callbacks.
- Clean-commit macOS arm64 peak-RSS observations for LLVM/QBE bounded, failing and slow sink workloads.
- Deterministic Phase 10 property corpus covering UTF-8/control encoding, maximum-size values, scalar field boundaries and malformed typed configuration on LLVM/QBE.
- Deterministic rotation/path property corpus covering portable and hostile paths, every C0 control plus DEL, archive ownership and component-boundary confinement.
- Bounded multi-process file/rotation stress harness with repeated reopen/close cycles, timeout, peak-RSS observation, exact JSONL/retention accounting and sentinel scans.
- Reproducible seeded NOX fuzz corpus covering 2,048 JSON/text encoding, scalar field, mixed-case redaction, path/archive and configuration cases.

### Changed

- Pinned NOX toolchain installation in CI and release preflight now uses the GitHub Release API with bounded retries while retaining SHA-256 verification.
- Baseline message masking now avoids calling the stdlib assignment masker when no sensitive key candidate is present, preserving arbitrary control characters for safe formatter escaping.
- Package-internal, test and example imports now use the manifest package name so installed dependency graphs resolve transitively.
- Stderr selection now fails explicitly instead of falling back silently because the pinned NOX API exposes stdout only.
- File names containing recognized credential-key components are rejected before opening a handle.
- Recognized credential-key directory components are rejected before opening a file, including mixed-case names followed by a path separator.
- JSONL records include optional top-level correlation identifiers; text records render them in fixed request/trace/span order.
- Rotating output rejects oversized records/preexisting files rather than exceeding the configured storage budget.
- Async dispatch remains disabled after the Phase 7 audit, revalidated on NOX 2.1.0, found no portable non-blocking overflow or timeout-aware worker shutdown contract.
- Hermetic package and import harnesses accept an explicit `NOXC` binary override for pinned local verification.
- Sink/filter failures now default to non-raising observable diagnostics while explicit strict mode raises fixed sanitized categories.
- The pinned compiler baseline is now NOX 2.1.0 so Phase 9 can test current ecosystem releases; the complete existing suite remains green locally on LLVM and QBE.
- Request adapters collect only allowlisted method/status/duration and optional explicit route metadata; raw targets, queries, headers and bodies remain excluded.
- File path validation rejects control characters before invoking native path or regex helpers, and component confinement rejects non-canonical `.`/`..` inputs directly.

### Security

- Security fixtures use synthetic sentinels; redactor exceptions are dropped before fan-out and their messages are not emitted.
- Custom filters receive only sanitized clones; exceptions, mutation and re-entry cannot expose an unsafe record or block later safe routes.
