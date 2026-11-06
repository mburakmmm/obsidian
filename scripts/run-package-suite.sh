#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-package-suite.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"

mkdir -p "$package_root/sinks" "$consumer_root/tests" "$consumer_root/examples" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root"/*.nox "$package_root/"
cp "$project_root/sinks"/*.nox "$package_root/sinks/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian package suite"
git -C "$package_root" config user.email "package-suite@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "package suite fixture"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" noxc init . >/dev/null
cp -R "$project_root/tests/." tests/
cp -R "$project_root/examples/." examples/
NOX_HOME="$probe_nox_home" noxc add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" noxc fetch >/dev/null

NOX_HOME="$probe_nox_home" noxc test --backend "$backend" tests

expected_json='{"timestamp":"2023-11-14T22:13:20.123Z","timestamp_ms":1700000000123,"level":"INFO","logger":"service.auth","message":"request completed","fields":{"status":200,"token":"***","user_id":"u-123"},"context":{"request":"req-42"},"schema_version":"obsidian.log.v1"}'
test "$(NOX_HOME="$probe_nox_home" noxc run --backend "$backend" examples/hello.nox)" = "obsidian 0.0.0"
test "$(NOX_HOME="$probe_nox_home" noxc run --backend "$backend" examples/memory_logging.nox)" = "1700000000000 INFO service.auth password=*** ***"
test "$(NOX_HOME="$probe_nox_home" noxc run --backend "$backend" examples/json_logging.nox)" = "$expected_json"

resolved_sha="$(git -C "$package_root" rev-parse HEAD)"
grep -q "\"resolved\": \"$resolved_sha\"" nox.lock

printf 'package suite: backend=%s tests=pass examples=pass lock=pass\n' "$backend"
