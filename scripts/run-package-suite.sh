#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("$1" != "llvm" && "$1" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-package-suite.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"

mkdir -p "$package_root/adapters" "$package_root/sinks" "$consumer_root/tests" "$consumer_root/examples" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root"/*.nox "$package_root/"
cp "$project_root/adapters"/*.nox "$package_root/adapters/"
cp "$project_root/sinks"/*.nox "$package_root/sinks/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian package suite"
git -C "$package_root" config user.email "package-suite@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "package suite fixture"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
cp -R "$project_root/tests/." tests/
cp -R "$project_root/examples/." examples/
NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

mkdir -p "$consumer_root/obsidian-file-tests" "$consumer_root/obsidian-file-denied" "$consumer_root/obsidian-rotation-tests/main" "$consumer_root/obsidian-rotation-tests/dry" "$consumer_root/obsidian-rotation-tests/rename" "$consumer_root/obsidian-rotation-tests/oversized" "$consumer_root/obsidian-rotation-tests/oversized-active" "$consumer_root/obsidian-rotation-tests/unexpected" "$consumer_root/obsidian-rotation-tests/symlink" "$consumer_root/obsidian-rotation-tests/active-link" "$consumer_root/obsidian-rotation-tests/security" "$consumer_root/obsidian-rotation-tests/crash" "$consumer_root/obsidian-rotation-tests/config" "$consumer_root/obsidian-rotation-tests/pending" "$consumer_root/obsidian-rotation-tests/zero" "$probe_root/outside"
ln -s "$probe_root/outside" "$consumer_root/obsidian-file-tests/escape-link"
touch "$consumer_root/obsidian-rotation-tests/symlink/unrelated.log" "$consumer_root/obsidian-rotation-tests/active-link/unrelated.log"
ln -s "$consumer_root/obsidian-rotation-tests/symlink/unrelated.log" "$consumer_root/obsidian-rotation-tests/symlink/events.jsonl.00000001"
ln -s "$consumer_root/obsidian-rotation-tests/active-link/unrelated.log" "$consumer_root/obsidian-rotation-tests/active-link/events.jsonl"
chmod 500 "$consumer_root/obsidian-file-denied"

if ! test_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" test --backend "$backend" tests 2>&1)"; then
  if [[ "$test_output" == *SYNTHETIC_* ]]; then
    echo "test suite failed and captured output contained a security sentinel" >&2
    exit 1
  fi
  printf '%s\n' "$test_output"
  exit 1
fi
printf '%s\n' "$test_output"
if [[ "$test_output" == *SYNTHETIC_* ]]; then
  echo "security sentinel appeared in captured test output" >&2
  exit 1
fi

expected_json='{"timestamp":"2023-11-14T22:13:20.123Z","timestamp_ms":1700000000123,"level":"INFO","logger":"service.auth","message":"request completed","fields":{"status":200,"token":"***","user_id":"u-123"},"context":{"request":"req-42"},"schema_version":"obsidian.log.v1"}'
expected_console='2023-11-14T22:13:20.123Z INFO service.auth token="***" password=***'
expected_file='{"timestamp":"2023-11-14T22:13:20.123Z","timestamp_ms":1700000000123,"level":"INFO","logger":"service.file","message":"file event","fields":{"token":"***"},"context":{},"schema_version":"obsidian.log.v1"}'
expected_security='2023-11-14T22:13:20.123Z INFO service.security client_pin="***" Bearer *** https://***:***@example.com/?token=***'
expected_context='{"timestamp":"2023-11-14T22:13:20.123Z","timestamp_ms":1700000000123,"level":"INFO","logger":"service.http","message":"request completed","fields":{"status":200},"context":{"route":"/health"},"request_id":"req-42","trace_id":"trace-7","span_id":"span-3","schema_version":"obsidian.log.v1"}'

run_exact_example() {
  local source_file="$1"
  local expected="$2"
  local output
  if ! output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" "$source_file" 2>&1)"; then
    if [[ "$output" == *SYNTHETIC_* ]]; then
      echo "example failed and captured output contained a security sentinel" >&2
    else
      echo "example failed: $source_file" >&2
    fi
    exit 1
  fi
  if [[ "$output" == *SYNTHETIC_* ]]; then
    echo "security sentinel appeared in captured example output" >&2
    exit 1
  fi
  test "$output" = "$expected"
}

run_exact_example examples/hello.nox "obsidian 0.0.0"
run_exact_example examples/memory_logging.nox "1700000000000 INFO service.auth password=*** ***"
run_exact_example examples/json_logging.nox "$expected_json"
run_exact_example examples/console_logging.nox "$expected_console"
run_exact_example examples/file_logging.nox "$expected_file"
run_exact_example examples/security_redaction.nox "$expected_security"
run_exact_example examples/request_context.nox "$expected_context"
run_exact_example examples/file_rotation.nox "rotations=1 archives=1 bounded=true"
run_exact_example examples/filtering.nox "all=2 errors=1 matched=2 filter_failures=0"

resolved_sha="$(git -C "$package_root" rev-parse HEAD)"
grep -q "\"resolved\": \"$resolved_sha\"" nox.lock

printf 'package suite: backend=%s tests=pass examples=pass lock=pass\n' "$backend"
