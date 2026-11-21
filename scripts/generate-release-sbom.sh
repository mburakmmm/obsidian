#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
test "$("$noxc_bin" --version 2>&1)" = "noxc 2.2.38"
scratch="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-sbom.XXXXXX")"
trap 'rm -rf "$scratch"' EXIT
cd "$project_root"

NOX_HOME="$scratch/home" "$noxc_bin" sbom . > "$scratch/first.json"
NOX_HOME="$scratch/home" "$noxc_bin" sbom . > "$scratch/second.json"
cmp "$scratch/first.json" "$scratch/second.json"
version="$(jq -er .version nox.json)"
if ! jq -e --arg version "$version" '
  .bomFormat == "CycloneDX" and .specVersion == "1.5" and
  .metadata.component.name == "obsidian" and
  (.metadata.component.version // $version) == $version and
  .components == [] and
  any(.metadata.component.properties[]; .name == "nox:native" and .value == "false")
' "$scratch/first.json" >/dev/null; then
  echo "SBOM does not match the Obsidian manifest and pure-NOX dependency policy" >&2
  exit 1
fi
jq --arg version "$version" '.metadata.component.version = $version' "$scratch/first.json"
