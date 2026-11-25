#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
noxc_bin="${NOXC:-noxc}"
probe_root="$(mktemp -d "${TMPDIR:-/tmp}/obsidian-async-audit.XXXXXX")"
trap 'rm -rf "$probe_root"' EXIT
probe_nox_home="$probe_root/nox-home"
mkdir -p "$probe_nox_home"

expect_check_failure() {
  local source_file="$1"
  local expected="$2"
  local output_file="$probe_root/$(basename "$source_file").check"
  if NOX_HOME="$probe_nox_home" "$noxc_bin" check "$source_file" >"$output_file" 2>&1; then
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
  if NOX_HOME="$probe_nox_home" "$noxc_bin" run --backend "$backend" "$source_file" >"$output_file" 2>&1; then
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
  output="$(NOX_HOME="$probe_nox_home" NOX_POOL_WORKERS=4 "$noxc_bin" run --backend "$backend" "$source_file" 2>&1)"
  if [[ "$output" != "$expected" ]]; then
    echo "async capability probe output mismatch: $source_file ($backend)" >&2
    exit 1
  fi
}

expect_bounded_overlap_run() {
  local backend="$1"
  local source_file="$2"
  local output
  output="$(NOX_HOME="$probe_nox_home" NOX_POOL_WORKERS=4 "$noxc_bin" run --backend "$backend" "$source_file" 2>&1)"
  case "$output" in
    "2 True")
      overlap_result="observed"
      ;;
    "1 True")
      overlap_result="not-observed"
      ;;
    *)
      echo "async capability probe output mismatch: $source_file ($backend): $output" >&2
      exit 1
      ;;
  esac
}

capability_root="$project_root/tests/capability"
expect_check_failure "$capability_root/async_try_send.nox" "no method 'try_send'"
expect_check_failure "$capability_root/async_timed_join.nox" "'join' takes no arguments"
expect_exact_run llvm "$capability_root/async_record_channel.nox" "7"
expect_exact_run qbe "$capability_root/async_qbe_scalar_channel.nox" "1 1"
overlap_result="not-run"
expect_bounded_overlap_run llvm "$capability_root/async_worker_overlap.nox"
llvm_overlap="$overlap_result"
noxc_version="$("$noxc_bin" --version 2>&1)"
case "$noxc_version" in
  "noxc 2.1.0")
    expect_check_failure "$capability_root/async_thread_cancel.nox" "no method 'cancel'"
    expect_run_failure qbe "$capability_root/async_record_channel.nox" "'ThreadChannel' element type"
    expect_run_failure llvm "$capability_root/async_sync_send.nox" "codegen:"
    echo "async capability audit: decision=no-go llvm-overlap=$llvm_overlap qbe-scalar-transfer=pass"
    ;;
  "noxc 2.2.38"|"noxc 2.2.70")
    expect_check_failure "$capability_root/async_sync_send.nox" "'send' suspends the task"
    expect_exact_run qbe "$capability_root/async_record_channel.nox" "7"
    expect_bounded_overlap_run qbe "$capability_root/async_worker_overlap.nox"
    for backend in llvm qbe; do
      if [[ "$noxc_version" == "noxc 2.2.70" ]]; then
        expect_exact_run "$backend" "$capability_root/async_task_recv_cancel.nox" "-1 7"
        expect_exact_run "$backend" "$capability_root/async_thread_recv_cancel.nox" "0"
        printf 'recv cancellation: backend=%s task=typed-cancel thread=scalar-zero\n' "$backend"
      else
        expect_run_failure "$backend" "$capability_root/async_thread_cancel.nox" "deadlock detected"
      fi
    done
    echo "async capability audit: decision=no-go llvm-overlap=$llvm_overlap qbe-overlap=$overlap_result both-class-transfer=pass"
    ;;
  *)
    echo "async capability audit: select a supported audit compiler (2.1.0, 2.2.38 or 2.2.70)" >&2
    exit 2
    ;;
esac
