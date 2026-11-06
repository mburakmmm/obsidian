#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("${1:-}" != "llvm" && "${1:-}" != "qbe" && "${1:-}" != "all") ]]; then
  echo "usage: $0 <llvm|qbe|all>" >&2
  exit 2
fi

requested_backend="$1"
backends=("$requested_backend")
if [[ "$requested_backend" == "all" ]]; then
  backends=(llvm qbe)
fi
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-ecosystem-suite.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
probe_nox_home="$probe_root/nox-home"
mkdir -p "$package_root/adapters" "$package_root/sinks" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root"/*.nox "$package_root/"
cp "$project_root/adapters"/*.nox "$package_root/adapters/"
cp "$project_root/sinks"/*.nox "$package_root/sinks/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian ecosystem suite"
git -C "$package_root" config user.email "ecosystem-suite@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "ecosystem suite fixture"

run_probe() {
  local alias="$1"
  local repository="$2"
  local reference="$3"
  local expected_sha="$4"
  local source_file="$5"
  local example_file="$6"
  local consumer_root="$probe_root/$alias-consumer"
  local output
  local backend

  mkdir -p "$consumer_root"
  cd "$consumer_root"
  NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
  cp "$source_file" main.nox
  cp "$example_file" example.nox
  NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian "$package_root" --ref main >/dev/null
  NOX_HOME="$probe_nox_home" "$noxc_bin" add "$alias" "$repository" --ref "$reference" >/dev/null
  NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

  grep -q "\"resolved\": \"$expected_sha\"" nox.lock
  for backend in "${backends[@]}"; do
    if ! output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" main.nox 2>&1)"; then
      if [[ "$output" == *SYNTHETIC_* ]]; then
        echo "$alias probe failed and captured output contained a security sentinel" >&2
      else
        printf '%s\n' "$output"
      fi
      exit 1
    fi
    if [[ "$output" == *SYNTHETIC_* ]]; then
      echo "$alias probe output contained a security sentinel" >&2
      exit 1
    fi
    if ! output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" example.nox 2>&1)"; then
      printf '%s\n' "$output"
      exit 1
    fi
    if [[ "$output" == *SYNTHETIC_* ]]; then
      echo "$alias example output contained a security sentinel" >&2
      exit 1
    fi
    printf 'ecosystem probe: adapter=%s ref=%s backend=%s probe=pass example=pass\n' "$alias" "$reference" "$backend"
  done
}

run_probe nyx github.com/mburakmmm/nyx v0.24.0 b4ef854badb8478f074e4b89fd864b48633b023c "$project_root/tests/ecosystem/nyx_adapter_probe.nox" "$project_root/examples/integrations/nyx_request_logging.nox"
run_probe aether github.com/mburakmmm/aether v0.9.0 d283a3badd1585dba1c58685dfa4d376f59262b8 "$project_root/tests/ecosystem/aether_adapter_probe.nox" "$project_root/examples/integrations/aether_request_logging.nox"
run_probe quartz github.com/mburakmmm/quartz v0.9.15 a8e0b9bd2d3e71bb61d192362b158a74c3212f38 "$project_root/tests/ecosystem/quartz_adapter_probe.nox" "$project_root/examples/integrations/quartz_capture.nox"
