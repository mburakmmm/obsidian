#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-async-audit.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT

expect_check_failure() {
  local source_file="$1"
  local expected="$2"
  local output_file="$probe_root/$(basename "$source_file").check"
  if "$noxc_bin" check "$source_file" >"$output_file" 2>&1; then
    echo "async capability probe unexpectedly type-checked: $source_file" >&2
    exit 1
  fi
  if ! grep -q "$expected" "$output_file"; then
    echo "async capability probe failed for an unexpected reason: $source_file" >&2
    exit 1
  fi
}

expect_run_failure() {
  local backend="$1"
  local source_file="$2"
  local expected="$3"
  local output_file="$probe_root/$(basename "$source_file").$backend"
  if "$noxc_bin" run --backend "$backend" "$source_file" >"$output_file" 2>&1; then
    echo "async capability probe unexpectedly ran: $source_file ($backend)" >&2
    exit 1
  fi
  if ! grep -q "$expected" "$output_file"; then
    echo "async capability probe failed for an unexpected reason: $source_file ($backend)" >&2
    exit 1
  fi
}

expect_exact_run() {
  local backend="$1"
  local source_file="$2"
  local expected="$3"
  local output
  output="$(NOX_POOL_WORKERS=4 "$noxc_bin" run --backend "$backend" "$source_file" 2>&1)"
  if [[ "$output" != "$expected" ]]; then
    echo "async capability probe output mismatch: $source_file ($backend)" >&2
    exit 1
  fi
}

capability_root="$project_root/tests/capability"
expect_check_failure "$capability_root/async_try_send.nox" "no method 'try_send'"
expect_check_failure "$capability_root/async_thread_cancel.nox" "no method 'cancel'"
expect_check_failure "$capability_root/async_timed_join.nox" "'join' takes no arguments"
expect_run_failure qbe "$capability_root/async_record_channel.nox" "'ThreadChannel' element type"
expect_run_failure llvm "$capability_root/async_sync_send.nox" "codegen:"
expect_exact_run llvm "$capability_root/async_record_channel.nox" "7"
expect_exact_run llvm "$capability_root/async_worker_overlap.nox" "2 True"
expect_exact_run qbe "$capability_root/async_qbe_scalar_channel.nox" "1 1"

echo "async capability audit: decision=no-go llvm-overlap=2 qbe-scalar-transfer=pass"
