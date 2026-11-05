# Contributing to Obsidian

Obsidian is developed phase by phase under the contract in `AGENTS.md`. Begin with `todo.md` and `docs/compatibility.md`; proposed code that skips the active phase gate will not be merged.

## Development workflow

1. Open an issue for public API, schema, security-policy or architecture changes.
2. Keep each change small and scoped to one phase acceptance criterion.
3. Verify uncertain NOX behavior in a minimal compile test before using it in library code.
4. Add positive, negative and security tests as appropriate.
5. Update API documentation, examples and the changelog in the same change.

Required local checks:

```sh
noxc test --backend llvm tests
noxc test --backend qbe tests
bash scripts/verify-package-import.sh
```

Compile-fail fixtures under `tests/compile_fail` are successful only when `noxc check` exits non-zero.

Never place credentials, private logs or production data in issues, tests or commits. Use synthetic sentinels and follow `SECURITY.md` for vulnerability reports.

Pull requests must report exact test-file, assertion and skip totals. A skipped test is missing evidence, not a pass.
