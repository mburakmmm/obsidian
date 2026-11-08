#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 || ("${1:-}" != "llvm" && "${1:-}" != "qbe") || ("${2:-}" != "smoke" && "${2:-}" != "full") ]]; then
  echo "usage: $0 <llvm|qbe> <smoke|full>" >&2
  exit 2
fi

backend="$1"
mode="$2"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-file-stress.XXXXXX")"
trap 'rm -rf -- "$probe_root"' EXIT

if [[ "$mode" == "smoke" ]]; then
  iterations=8000
  rounds=1
  timeout_seconds=60
else
  iterations=40000
  rounds=3
  timeout_seconds=120
fi

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"
binary="$probe_root/file-stress"
mkdir -p "$package_root/adapters" "$package_root/sinks" "$consumer_root" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root"/*.nox "$package_root/"
cp "$project_root/adapters"/*.nox "$package_root/adapters/"
cp "$project_root/sinks"/*.nox "$package_root/sinks/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian file stress"
git -C "$package_root" config user.email "file-stress@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "file stress fixture"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
cp "$project_root/benchmarks/file_stress.nox" main.nox
NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null
if ! build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$binary" main.nox 2>&1)"; then
  if [[ "$build_output" == *SYNTHETIC_* ]]; then
    echo "file stress build failure output contained a security sentinel" >&2
  else
    printf '%s\n' "$build_output" >&2
  fi
  exit 1
fi

compiler_version="$($noxc_bin --version 2>&1)"
source_commit="$(git -C "$project_root" rev-parse HEAD)"
dirty="false"
if [[ -n "$(git -C "$project_root" status --porcelain)" ]]; then
  dirty="true"
fi
printf 'stress_environment schema=obsidian.file-stress-environment.v1 os=%s kernel=%s arch=%s compiler=%q nox_source=%s obsidian_commit=%s dirty=%s backend=%s mode=%s\n' \
  "$(uname -s)" "$(uname -r)" "$(uname -m)" "$compiler_version" \
  "fd107b922c67a804520dc30f849039d977542f6c" "$source_commit" "$dirty" "$backend" "$mode"

if ! output="$(python3 "$project_root/scripts/run-file-stress.py" "$binary" "$iterations" "$rounds" "$timeout_seconds" 2>&1)"; then
  if [[ "$output" == *SYNTHETIC_* ]]; then
    echo "file stress failure output contained a security sentinel" >&2
  else
    printf '%s\n' "$output" >&2
  fi
  exit 1
fi
if [[ "$output" == *SYNTHETIC_* ]]; then
  echo "file stress output contained a security sentinel" >&2
  exit 1
fi
printf '%s\n' "$output"
