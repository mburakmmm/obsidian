#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if rg -n '^(from|import) (nyx|aether|quartz)(\.| |$)' \
  --glob '*.nox' \
  --glob '!adapters/**' \
  --glob '!tests/ecosystem/**' \
  --glob '!examples/integrations/**' \
  "$project_root"; then
  echo "core source imports an optional ecosystem package" >&2
  exit 1
fi

if ! rg -U '"requires"\s*:\s*\[\s*\]' "$project_root/nox.json" >/dev/null; then
  echo "core manifest must not contain ecosystem dependencies" >&2
  exit 1
fi

printf 'dependency audit: core=stdlib-only optional-adapters=nyx,aether,quartz\n'
