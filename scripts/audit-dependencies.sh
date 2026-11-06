#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ecosystem_imports="$(find "$project_root" -type f -name '*.nox' \
  ! -path "$project_root/adapters/*" \
  ! -path "$project_root/tests/ecosystem/*" \
  ! -path "$project_root/examples/integrations/*" \
  -exec grep -nE '^(from|import) (nyx|aether|quartz)(\.| |$)' {} + || true)"
if [[ -n "$ecosystem_imports" ]]; then
  printf '%s\n' "$ecosystem_imports"
  echo "core source imports an optional ecosystem package" >&2
  exit 1
fi

manifest_compact="$(tr -d '[:space:]' <"$project_root/nox.json")"
if [[ "$manifest_compact" != *'"requires":[]'* ]]; then
  echo "core manifest must not contain ecosystem dependencies" >&2
  exit 1
fi

printf 'dependency audit: core=stdlib-only optional-adapters=nyx,aether,quartz\n'
