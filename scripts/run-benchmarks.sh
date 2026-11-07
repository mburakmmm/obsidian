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

cp "$project_root/benchmarks/console_bench.nox" main.nox
console_output="$probe_root/console-output.txt"
console_error="$probe_root/console-error.txt"
if ! NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" main.nox >"$console_output" 2>"$console_error"; then
  cat "$console_error" >&2
  cat "$console_output"
  exit 1
fi
if [[ -s "$console_error" ]]; then
  cat "$console_error" >&2
  echo "console benchmark emitted unexpected stderr output" >&2
  exit 1
fi
if grep -q 'SYNTHETIC_' "$console_output"; then
  echo "console benchmark output contained a security sentinel" >&2
  exit 1
fi
expected_console_lines=14202
actual_console_lines="$(wc -l <"$console_output" | tr -d '[:space:]')"
if [[ "$actual_console_lines" != "$expected_console_lines" ]]; then
  echo "console benchmark line count mismatch: expected $expected_console_lines, got $actual_console_lines" >&2
  exit 1
fi
schema_line="$(grep '^benchmark_schema=obsidian.console-benchmark.v1 ' "$console_output")"
result_line="$(grep '^benchmark=console_info_text ' "$console_output")"
if [[ -z "$schema_line" || -z "$result_line" ]]; then
  echo "console benchmark report is missing" >&2
  exit 1
fi
printf '%s\n' "$schema_line"
printf '%s redirected_lines=%s\n' "$result_line" "$actual_console_lines"

cp "$project_root/benchmarks/file_bench.nox" main.nox
if ! file_benchmark_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" main.nox 2>&1)"; then
  printf '%s\n' "$file_benchmark_output"
  exit 1
fi
if [[ "$file_benchmark_output" == *SYNTHETIC_* ]]; then
  echo "file benchmark report contained a security sentinel" >&2
  exit 1
fi
file_output="$consumer_root/benchmark-output/plain/events.jsonl"
rotation_output="$consumer_root/benchmark-output/rotation/events.jsonl"
if [[ ! -f "$file_output" || ! -f "$rotation_output" ]]; then
  echo "file benchmark output is missing" >&2
  exit 1
fi
if grep -r -q 'SYNTHETIC_' "$consumer_root/benchmark-output"; then
  echo "file benchmark output contained a security sentinel" >&2
  exit 1
fi
if ! grep -F -q '"***"' "$file_output" || ! grep -F -q '"***"' "$rotation_output"; then
  echo "file benchmark did not exercise field redaction" >&2
  exit 1
fi
expected_file_lines=14200
actual_file_lines="$(wc -l <"$file_output" | tr -d '[:space:]')"
if [[ "$actual_file_lines" != "$expected_file_lines" ]]; then
  echo "file benchmark line count mismatch: expected $expected_file_lines, got $actual_file_lines" >&2
  exit 1
fi
actual_file_bytes="$(wc -c <"$file_output" | tr -d '[:space:]')"
file_bytes_per_event="$((actual_file_bytes / actual_file_lines))"
if [[ "$((file_bytes_per_event * actual_file_lines))" != "$actual_file_bytes" ]]; then
  echo "file benchmark output size is not uniform" >&2
  exit 1
fi
actual_rotation_lines="$(wc -l <"$rotation_output" | tr -d '[:space:]')"
if [[ "$actual_rotation_lines" != "1" ]]; then
  echo "rotation benchmark active file line count mismatch" >&2
  exit 1
fi
archive_count="$(find "$consumer_root/benchmark-output/rotation" -type f -name 'events.jsonl.*' | wc -l | tr -d '[:space:]')"
if [[ "$archive_count" != "0" ]]; then
  echo "rotation benchmark retained an unexpected archive" >&2
  exit 1
fi
file_schema_line="$(printf '%s\n' "$file_benchmark_output" | grep '^benchmark_schema=obsidian.file-benchmark.v1 ')"
file_result_line="$(printf '%s\n' "$file_benchmark_output" | grep '^benchmark=file_info_json ')"
rotation_result_line="$(printf '%s\n' "$file_benchmark_output" | grep '^benchmark=rotation_pause ')"
if [[ -z "$file_schema_line" || -z "$file_result_line" || -z "$rotation_result_line" ]]; then
  echo "file benchmark report is missing" >&2
  exit 1
fi
printf '%s\n' "$file_schema_line"
printf '%s file_lines=%s bytes_per_event=%s\n' "$file_result_line" "$actual_file_lines" "$file_bytes_per_event"
printf '%s active_lines=%s retained_archives=%s\n' "$rotation_result_line" "$actual_rotation_lines" "$archive_count"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required for the process-startup benchmark" >&2
  exit 1
fi
empty_binary="$probe_root/process-empty"
logger_binary="$probe_root/process-logger"
cp "$project_root/benchmarks/process_empty.nox" main.nox
if ! empty_build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$empty_binary" main.nox 2>&1)"; then
  printf '%s\n' "$empty_build_output"
  exit 1
fi
cp "$project_root/benchmarks/process_logger.nox" main.nox
if ! logger_build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$logger_binary" main.nox 2>&1)"; then
  printf '%s\n' "$logger_build_output"
  exit 1
fi
if ! startup_output="$(python3 "$project_root/scripts/measure-process-startup.py" "$empty_binary" "$logger_binary" 2>&1)"; then
  printf '%s\n' "$startup_output"
  exit 1
fi
if [[ "$startup_output" == *SYNTHETIC_* ]]; then
  echo "startup benchmark report contained a security sentinel" >&2
  exit 1
fi
startup_line_count="$(printf '%s\n' "$startup_output" | wc -l | tr -d '[:space:]')"
if [[ "$startup_line_count" != "3" ]]; then
  echo "startup benchmark emitted unexpected output" >&2
  exit 1
fi
startup_schema_line="$(printf '%s\n' "$startup_output" | grep '^benchmark_schema=obsidian.process-startup-benchmark.v1 ')"
empty_startup_line="$(printf '%s\n' "$startup_output" | grep '^benchmark=process_startup_empty ')"
logger_startup_line="$(printf '%s\n' "$startup_output" | grep '^benchmark=process_startup_logger ')"
if [[ -z "$startup_schema_line" || -z "$empty_startup_line" || -z "$logger_startup_line" ]]; then
  echo "startup benchmark report is missing" >&2
  exit 1
fi
printf '%s\n' "$startup_schema_line"
printf '%s\n' "$empty_startup_line"
printf '%s\n' "$logger_startup_line"

bounded_memory_binary="$probe_root/memory-bounded"
failing_memory_binary="$probe_root/memory-failing"
slow_memory_binary="$probe_root/memory-slow"
cp "$project_root/benchmarks/memory_bounded.nox" main.nox
if ! bounded_build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$bounded_memory_binary" main.nox 2>&1)"; then
  printf '%s\n' "$bounded_build_output"
  exit 1
fi
cp "$project_root/benchmarks/memory_failing.nox" main.nox
if ! failing_build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$failing_memory_binary" main.nox 2>&1)"; then
  printf '%s\n' "$failing_build_output"
  exit 1
fi
cp "$project_root/benchmarks/memory_slow.nox" main.nox
if ! slow_build_output="$(NOX_HOME="$probe_nox_home" "$noxc_bin" build --backend "$backend" -o "$slow_memory_binary" main.nox 2>&1)"; then
  printf '%s\n' "$slow_build_output"
  exit 1
fi

empty_memory_output="$(python3 "$project_root/scripts/measure-process-memory.py" memory_empty_peak_rss "$empty_binary" -)"
bounded_memory_output="$(python3 "$project_root/scripts/measure-process-memory.py" memory_bounded_peak_rss "$bounded_memory_binary" 'probe=bounded_memory ')"
failing_memory_output="$(python3 "$project_root/scripts/measure-process-memory.py" memory_failing_peak_rss "$failing_memory_binary" 'probe=failing_sink ')"
slow_memory_output="$(python3 "$project_root/scripts/measure-process-memory.py" memory_slow_peak_rss "$slow_memory_binary" 'probe=slow_sink ')"
empty_memory_lines="$(printf '%s\n' "$empty_memory_output" | wc -l | tr -d '[:space:]')"
bounded_memory_lines="$(printf '%s\n' "$bounded_memory_output" | wc -l | tr -d '[:space:]')"
failing_memory_lines="$(printf '%s\n' "$failing_memory_output" | wc -l | tr -d '[:space:]')"
slow_memory_lines="$(printf '%s\n' "$slow_memory_output" | wc -l | tr -d '[:space:]')"
if [[ "$empty_memory_lines" != "2" || "$bounded_memory_lines" != "3" || "$failing_memory_lines" != "3" || "$slow_memory_lines" != "3" ]]; then
  echo "memory benchmark emitted unexpected output" >&2
  exit 1
fi
memory_schema_line="$(printf '%s\n' "$empty_memory_output" | grep '^benchmark_schema=obsidian.process-memory-benchmark.v1 ')"
bounded_memory_schema="$(printf '%s\n' "$bounded_memory_output" | grep '^benchmark_schema=obsidian.process-memory-benchmark.v1 ')"
failing_memory_schema="$(printf '%s\n' "$failing_memory_output" | grep '^benchmark_schema=obsidian.process-memory-benchmark.v1 ')"
slow_memory_schema="$(printf '%s\n' "$slow_memory_output" | grep '^benchmark_schema=obsidian.process-memory-benchmark.v1 ')"
empty_memory_line="$(printf '%s\n' "$empty_memory_output" | grep '^benchmark=memory_empty_peak_rss ')"
bounded_memory_line="$(printf '%s\n' "$bounded_memory_output" | grep '^benchmark=memory_bounded_peak_rss ')"
failing_memory_line="$(printf '%s\n' "$failing_memory_output" | grep '^benchmark=memory_failing_peak_rss ')"
slow_memory_line="$(printf '%s\n' "$slow_memory_output" | grep '^benchmark=memory_slow_peak_rss ')"
bounded_probe_line="$(printf '%s\n' "$bounded_memory_output" | grep '^probe=bounded_memory ')"
failing_probe_line="$(printf '%s\n' "$failing_memory_output" | grep '^probe=failing_sink ')"
slow_probe_line="$(printf '%s\n' "$slow_memory_output" | grep '^probe=slow_sink ')"
if [[ -z "$memory_schema_line" || -z "$empty_memory_line" || -z "$bounded_memory_line" || -z "$failing_memory_line" || -z "$slow_memory_line" || -z "$bounded_probe_line" || -z "$failing_probe_line" || -z "$slow_probe_line" ]]; then
  echo "memory benchmark report is missing" >&2
  exit 1
fi
if [[ "$bounded_memory_schema" != "$memory_schema_line" || "$failing_memory_schema" != "$memory_schema_line" || "$slow_memory_schema" != "$memory_schema_line" ]]; then
  echo "memory benchmark environment changed between probes" >&2
  exit 1
fi
if [[ "$empty_memory_output$bounded_memory_output$failing_memory_output$slow_memory_output" == *SYNTHETIC_* ]]; then
  echo "memory benchmark report contained a security sentinel" >&2
  exit 1
fi
printf '%s\n' "$memory_schema_line"
printf '%s\n' "$empty_memory_line"
printf '%s %s\n' "$bounded_memory_line" "$bounded_probe_line"
printf '%s %s\n' "$failing_memory_line" "$failing_probe_line"
printf '%s %s\n' "$slow_memory_line" "$slow_probe_line"
