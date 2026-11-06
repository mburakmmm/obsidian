# Security policy

Obsidian is pre-release software and does not yet expose a logging API.

Do not report vulnerabilities by placing secrets, credentials, private keys or production log samples in a public issue. Use only synthetic sentinels in tests and reproductions. Submit sensitive reports through [GitHub's private vulnerability reporting form](https://github.com/mburakmmm/obsidian/security/advisories/new) and provide the smallest sanitized reproduction possible.

Security-sensitive behavior is not considered complete until the Phase 4 acceptance matrix in `todo.md` passes. Redaction failures must fail closed; no sink, fallback diagnostic, snapshot or test failure may contain an unmasked sentinel.

The currently implemented scalar redaction boundary and its deliberate limits are documented in [`docs/security.md`](docs/security.md). Future exception, configuration, rotation, diagnostics and async features must rerun that matrix before expanding any security claim.
