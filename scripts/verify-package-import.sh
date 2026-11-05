#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-package-import.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"

mkdir -p "$package_root" "$consumer_root" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root/version.nox" "$package_root/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian package probe"
git -C "$package_root" config user.email "package-probe@example.invalid"
git -C "$package_root" add nox.json version.nox
git -C "$package_root" commit -q -m "package import probe"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" noxc init . >/dev/null
cp "$project_root/tests/fixtures/consumer_main.nox" main.nox
NOX_HOME="$probe_nox_home" noxc add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" noxc fetch >/dev/null

llvm_output="$(NOX_HOME="$probe_nox_home" noxc run --backend llvm main.nox)"
qbe_output="$(NOX_HOME="$probe_nox_home" noxc run --backend qbe main.nox)"

test "$llvm_output" = "0.0.0"
test "$qbe_output" = "0.0.0"

resolved_sha="$(git -C "$package_root" rev-parse HEAD)"
grep -q "\"resolved\": \"$resolved_sha\"" nox.lock

printf 'package import probe: LLVM=pass QBE=pass lock=pass\n'
