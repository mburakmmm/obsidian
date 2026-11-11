#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <ref> <expected-version> <expected-commit> <expected-noxc-version>" >&2
  exit 2
fi

release_ref="$1"
expected_version="$2"
expected_commit="$3"
expected_noxc_version="$4"
noxc_bin="${NOXC:-noxc}"
resource_dir="${NOX_RESOURCE_DIR:-}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-registry-install.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"
mkdir -p "$consumer_root/tests" "$consumer_root/examples" "$probe_nox_home"

if [[ "$("$noxc_bin" --version 2>&1)" != "noxc $expected_noxc_version" ]]; then
  echo "registry install requires noxc $expected_noxc_version" >&2
  exit 1
fi
if [[ -z "$resource_dir" || ! -d "$resource_dir/lib/nox/stdlib/nox" ]]; then
  echo "registry install requires NOX_RESOURCE_DIR for the pinned release" >&2
  exit 1
fi

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian --ref "$release_ref" >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

jq -e \
  --arg ref "$release_ref" \
  '.requires | length == 1 and .[0].alias == "obsidian" and .[0].repo == "github.com/mburakmmm/obsidian" and .[0].ref == $ref' \
  nox.json >/dev/null

jq -e \
  --arg ref "$release_ref" \
  --arg resolved "$expected_commit" \
  '.packages | length == 1 and .[0].alias == "obsidian" and .[0].repo == "github.com/mburakmmm/obsidian" and .[0].ref == $ref and .[0].resolved == $resolved' \
  nox.lock >/dev/null

cp "$project_root/tests/compatibility/stable_api_test.nox" tests/
cp "$project_root/tests/compatibility/schema_v1_test.nox" tests/
cp "$project_root/tests/fixtures/consumer_main.nox" main.nox
cp "$project_root/examples/hello.nox" examples/

run_backend() {
  local backend="$1"
  local test_output
  local consumer_output
  local version_output

  if ! test_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" test --backend "$backend" tests 2>&1)"; then
    if [[ "$test_output" == *SYNTHETIC_* ]]; then
      echo "registry compatibility tests failed and captured output contained a security sentinel" >&2
    else
      printf '%s\n' "$test_output" >&2
    fi
    exit 1
  fi
  if [[ "$test_output" == *SYNTHETIC_* ]]; then
    echo "security sentinel appeared in registry compatibility test output" >&2
    exit 1
  fi

  consumer_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" main.nox)"
  version_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" examples/hello.nox)"

  expected_json='{"timestamp":"1970-01-01T00:00:00.000Z","timestamp_ms":0,"level":"INFO","logger":"consumer","message":"package import","fields":{"ok":true},"context":{},"schema_version":"obsidian.log.v1"}'
  test "$consumer_output" = "$expected_json"
  test "$version_output" = "obsidian $expected_version"
}

run_backend llvm
run_backend qbe

printf 'registry install: ref=%s resolved=%s version=%s noxc=%s LLVM=pass QBE=pass\n' \
  "$release_ref" "$expected_commit" "$expected_version" "$expected_noxc_version"
