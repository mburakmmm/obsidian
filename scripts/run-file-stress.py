#!/usr/bin/env python3
import json
import os
from pathlib import Path
import platform
import resource
import subprocess
import sys
import tempfile
import time


def normalize_max_rss(raw_value: int) -> int:
    if sys.platform == "darwin":
        return raw_value
    return raw_value * 1024


def parse_report(report: str) -> dict[str, str]:
    if "\n" in report or not report.startswith("stress_schema=obsidian.file-stress.v1 "):
        raise RuntimeError("file stress report is invalid")
    values: dict[str, str] = {}
    for item in report.split():
        key, separator, value = item.partition("=")
        if not separator or not key or not value or key in values:
            raise RuntimeError("file stress report is malformed")
        values[key] = value
    required = {
        "stress_schema",
        "iterations",
        "segment_writes",
        "plain_writes",
        "plain_record_bytes",
        "plain_bytes",
        "rotation_record_bytes",
        "rotation_max_bytes",
        "rotations",
        "archives",
        "active_bytes",
        "retained_bytes",
    }
    if set(values) != required:
        raise RuntimeError("file stress report fields are invalid")
    return values


def validate_uniform_jsonl(path: Path, expected_lines: int, expected_logger: str) -> tuple[int, int]:
    if not path.is_file() or path.is_symlink():
        raise RuntimeError("file stress output is not a regular file")
    line_count = 0
    byte_count = 0
    first_line = b""
    with path.open("rb") as stream:
        for line in stream:
            if not line.endswith(b"\n") or b"SYNTHETIC_" in line:
                raise RuntimeError("file stress output failed security validation")
            if not first_line:
                first_line = line
                record = json.loads(line)
                if record.get("schema_version") != "obsidian.log.v1":
                    raise RuntimeError("file stress output schema is invalid")
                if record.get("logger") != expected_logger:
                    raise RuntimeError("file stress logger name is invalid")
                if record.get("fields", {}).get("token") != "***":
                    raise RuntimeError("file stress field was not masked")
            elif line != first_line:
                raise RuntimeError("file stress output changed unexpectedly")
            line_count += 1
            byte_count += len(line)
    if line_count != expected_lines:
        raise RuntimeError("file stress line count mismatch")
    return line_count, byte_count


def run_probe(binary: str, iterations: int, timeout_seconds: int) -> dict[str, object]:
    started = time.monotonic_ns()
    with tempfile.TemporaryDirectory(prefix="obsidian-file-stress.") as directory:
        try:
            completed = subprocess.run(
                [binary, str(iterations)],
                cwd=directory,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                check=False,
                timeout=timeout_seconds,
            )
        except subprocess.TimeoutExpired as error:
            raise RuntimeError("file stress probe timed out") from error
        if completed.returncode != 0:
            raise RuntimeError("file stress probe exited unsuccessfully")
        if completed.stderr:
            raise RuntimeError("file stress probe emitted unexpected stderr")
        report = completed.stdout.decode("utf-8", errors="strict").strip()
        if "SYNTHETIC_" in report:
            raise RuntimeError("file stress report leaked a security sentinel")
        values = parse_report(report)
        if int(values["iterations"]) != iterations or int(values["plain_writes"]) != iterations:
            raise RuntimeError("file stress iteration accounting mismatch")

        output_root = Path(directory) / "stress-output"
        plain_path = output_root / "plain" / "events.jsonl"
        plain_lines, plain_bytes = validate_uniform_jsonl(plain_path, iterations, "stress.plain")
        if plain_bytes != int(values["plain_bytes"]):
            raise RuntimeError("plain file stress byte accounting mismatch")

        rotation_directory = output_root / "rotation"
        active_path = rotation_directory / "events.jsonl"
        expected_active_lines = int(values["rotation_max_bytes"]) // int(values["rotation_record_bytes"])
        active_lines, active_bytes = validate_uniform_jsonl(active_path, expected_active_lines, "stress.rotation")
        archives = sorted(rotation_directory.glob("events.jsonl.[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]"))
        if len(archives) != int(values["archives"]):
            raise RuntimeError("file stress archive inventory mismatch")
        expected_rotations = int(values["rotations"])
        expected_names = [
            f"events.jsonl.{sequence:08d}"
            for sequence in range(expected_rotations - len(archives) + 1, expected_rotations + 1)
        ]
        if [path.name for path in archives] != expected_names:
            raise RuntimeError("file stress archive sequence mismatch")
        retained_lines = active_lines
        retained_bytes = active_bytes
        for archive in archives:
            archive_lines, archive_bytes = validate_uniform_jsonl(archive, expected_active_lines, "stress.rotation")
            retained_lines += archive_lines
            retained_bytes += archive_bytes
        if retained_bytes != int(values["retained_bytes"]):
            raise RuntimeError("file stress retained byte accounting mismatch")
        entries = list(rotation_directory.iterdir())
        if len(entries) != len(archives) + 1:
            raise RuntimeError("file stress created an unexpected rotation entry")

        elapsed_ms = (time.monotonic_ns() - started) // 1_000_000
        usage = resource.getrusage(resource.RUSAGE_CHILDREN)
        return {
            "report": report,
            "elapsed_ms": elapsed_ms,
            "max_rss_bytes": normalize_max_rss(usage.ru_maxrss),
            "plain_lines": plain_lines,
            "retained_lines": retained_lines,
        }


def worker(binary: str, iterations: int, timeout_seconds: int) -> int:
    result = run_probe(binary, iterations, timeout_seconds)
    print(json.dumps(result, sort_keys=True))
    return 0


def run_round(binary: str, iterations: int, timeout_seconds: int) -> dict[str, object]:
    completed = subprocess.run(
        [sys.executable, __file__, "--worker", binary, str(iterations), str(timeout_seconds)],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0 or completed.stderr:
        raise RuntimeError("file stress worker failed")
    return json.loads(completed.stdout.decode("utf-8", errors="strict"))


def main() -> int:
    if len(sys.argv) == 5 and sys.argv[1] == "--worker":
        return worker(os.path.abspath(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]))
    if len(sys.argv) != 5:
        print(
            "usage: run-file-stress.py <binary> <iterations> <rounds> <timeout-seconds>",
            file=sys.stderr,
        )
        return 2
    binary = os.path.abspath(sys.argv[1])
    iterations = int(sys.argv[2])
    rounds = int(sys.argv[3])
    timeout_seconds = int(sys.argv[4])
    if not os.path.isfile(binary) or not os.access(binary, os.X_OK):
        raise RuntimeError("file stress binary is unavailable")
    if iterations < 1 or rounds < 1 or timeout_seconds < 1:
        raise RuntimeError("file stress runner arguments are invalid")

    reports: list[str] = []
    elapsed_samples: list[int] = []
    rss_samples: list[int] = []
    expected_plain_lines = iterations
    expected_retained_lines = 80
    for _ in range(rounds):
        result = run_round(binary, iterations, timeout_seconds)
        report = str(result["report"])
        if reports and report != reports[0]:
            raise RuntimeError("file stress report changed between rounds")
        if int(result["plain_lines"]) != expected_plain_lines:
            raise RuntimeError("file stress plain line evidence changed")
        if int(result["retained_lines"]) != expected_retained_lines:
            raise RuntimeError("file stress retained line evidence changed")
        reports.append(report)
        elapsed_samples.append(int(result["elapsed_ms"]))
        rss_samples.append(int(result["max_rss_bytes"]))

    print(
        "stress_runner_schema=obsidian.file-stress-runner.v1 "
        f"python={platform.python_version()} platform={sys.platform}"
    )
    print(
        f"stress=file_rotation rounds={rounds} iterations_per_round={iterations} "
        f"total_events_per_path={rounds * iterations} timeout_seconds={timeout_seconds} "
        f"mean_elapsed_ms={sum(elapsed_samples) // rounds} "
        f"min_elapsed_ms={min(elapsed_samples)} max_elapsed_ms={max(elapsed_samples)} "
        f"mean_peak_rss_bytes={sum(rss_samples) // rounds} "
        f"min_peak_rss_bytes={min(rss_samples)} max_peak_rss_bytes={max(rss_samples)}"
    )
    print(reports[0])
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
