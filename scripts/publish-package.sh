#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <ref>" >&2
  exit 2
fi

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
release_ref="$1"

cd "$project_root"
exec "$noxc_bin" publish github.com/mburakmmm/obsidian \
  --ref "$release_ref" \
  --description "Structured, secure logging and observability foundations for the NOX ecosystem" \
  --tags logging,observability,structured-logging,security \
  --source nox
