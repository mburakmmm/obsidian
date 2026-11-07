#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 || ("${1:-}" != "llvm" && "${1:-}" != "qbe") ]]; then
  echo "usage: $0 <llvm|qbe>" >&2
  exit 2
fi

backend="$1"
noxc_bin="${NOXC:-noxc}"
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-benchmark.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

package_root="$probe_root/package"
consumer_root="$probe_root/consumer"
probe_nox_home="$probe_root/nox-home"
mkdir -p "$package_root/adapters" "$package_root/sinks" "$consumer_root" "$probe_nox_home"
cp "$project_root/nox.json" "$project_root"/*.nox "$package_root/"
cp "$project_root/adapters"/*.nox "$package_root/adapters/"
cp "$project_root/sinks"/*.nox "$package_root/sinks/"

git -C "$package_root" init -q -b main
git -C "$package_root" config user.name "Obsidian benchmark"
git -C "$package_root" config user.email "benchmark@example.invalid"
git -C "$package_root" add .
git -C "$package_root" commit -q -m "benchmark fixture"

cd "$consumer_root"
NOX_HOME="$probe_nox_home" "$noxc_bin" init . >/dev/null
cp "$project_root/benchmarks/core_bench.nox" main.nox
NOX_HOME="$probe_nox_home" "$noxc_bin" add obsidian "$package_root" --ref main >/dev/null
NOX_HOME="$probe_nox_home" "$noxc_bin" fetch >/dev/null

compiler_version="$($noxc_bin --version 2>&1)"
source_commit="$(git -C "$project_root" rev-parse HEAD)"
dirty="false"
if [[ -n "$(git -C "$project_root" status --porcelain)" ]]; then
  dirty="true"
fi
cpu="unknown"
if command -v sysctl >/dev/null 2>&1; then
  cpu="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
fi
if [[ -z "$cpu" || "$cpu" == "unknown" ]] && command -v system_profiler >/dev/null 2>&1; then
  cpu="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F ': ' '/Chip:/{print $2; exit}')"
fi
if [[ -z "$cpu" || "$cpu" == "unknown" ]] && command -v lscpu >/dev/null 2>&1; then
  cpu="$(lscpu 2>/dev/null | awk -F ':' '/^Model name:/{sub(/^[[:space:]]+/, "", $2); print $2; exit}' || true)"
fi
if [[ -z "$cpu" || "$cpu" == "unknown" ]] && [[ -r /proc/cpuinfo ]]; then
  cpu="$(grep -m 1 -E '^(model name|Hardware|Processor)' /proc/cpuinfo | awk -F ': ' '{print $2}' || true)"
fi
if [[ -z "$cpu" || "$cpu" == "unknown" ]]; then
  cpu="$(uname -p 2>/dev/null || true)"
fi
if [[ -z "$cpu" ]]; then
  cpu="unknown"
fi

printf 'benchmark_environment schema=obsidian.benchmark.environment.v1 os=%s kernel=%s arch=%s cpu=%q compiler=%q nox_source=%s obsidian_commit=%s dirty=%s backend=%s\n' \
  "$(uname -s)" "$(uname -r)" "$(uname -m)" "$cpu" "$compiler_version" \
  "fd107b922c67a804520dc30f849039d977542f6c" "$source_commit" "$dirty" "$backend"

if ! output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" main.nox 2>&1)"; then
  printf '%s\n' "$output"
  exit 1
fi
if [[ "$output" == *SYNTHETIC_* ]]; then
  echo "benchmark output contained a security sentinel" >&2
  exit 1
fi
printf '%s\n' "$output"
