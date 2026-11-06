#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-package-import.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"

mkdir -p "$package_root" "$consumer_root" "$probe_nox_home"
cp \
  "$project_root/nox.json" \
  "$project_root/context.nox" \
  "$project_root/field_keys.nox" \
  "$project_root/field_set.nox" \
  "$project_root/fields.nox" \
  "$project_root/format_common.nox" \
  "$project_root/format_json.nox" \
  "$project_root/level.nox" \
  "$project_root/record.nox" \
  "$project_root/redact.nox" \
  "$package_root/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian package probe"
git -C "$package_root" config user.email "package-probe@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "package import probe"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
cp "$project_root/tests/fixtures/consumer_main.nox" main.nox
NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

llvm_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend llvm main.nox)"
qbe_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend qbe main.nox)"

expected='{"timestamp":"1970-01-01T00:00:00.000Z","timestamp_ms":0,"level":"INFO","logger":"consumer","message":"package import","fields":{"ok":true},"context":{},"schema_version":"obsidian.log.v1"}'
test "$llvm_output" = "$expected"
test "$qbe_output" = "$expected"

resolved_sha="$(git -C "$package_root" rev-parse HEAD)"
grep -q "\"resolved\": \"$resolved_sha\"" nox.lock

printf 'package import probe: LLVM=pass QBE=pass lock=pass\n'
