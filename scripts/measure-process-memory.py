#!/usr/bin/env python3
import json
import os
import platform
import resource
import subprocess
import sys

SAMPLE_COUNT = 7


def normalize_max_rss(raw_value: int) -> int:
    if sys.platform == "darwin":
        return raw_value
    return raw_value * 1024


def worker(binary: str, expected_prefix: str) -> int:
    completed = subprocess.run(
        [binary],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError("memory probe exited unsuccessfully")
    if completed.stderr:
        raise RuntimeError("memory probe emitted unexpected stderr")
    report = completed.stdout.decode("utf-8", errors="strict").strip()
    if expected_prefix == "-":
        if report:
            raise RuntimeError("empty memory probe emitted output")
    elif "\n" in report or not report.startswith(expected_prefix):
        raise RuntimeError("memory probe report is invalid")
    if "SYNTHETIC_" in report:
        raise RuntimeError("memory probe leaked a security sentinel")
    usage = resource.getrusage(resource.RUSAGE_CHILDREN)
    result = {"max_rss_bytes": normalize_max_rss(usage.ru_maxrss), "report": report}
    print(json.dumps(result, sort_keys=True))
    return 0


def measure(name: str, binary: str, expected_prefix: str) -> int:
    samples: list[int] = []
    expected_report = ""
    for _ in range(SAMPLE_COUNT):
        completed = subprocess.run(
            [sys.executable, __file__, "--worker", binary, expected_prefix],
            stdin=subprocess.DEVNULL,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            check=False,
        )
        if completed.returncode != 0 or completed.stderr:
            raise RuntimeError("memory measurement worker failed")
        result = json.loads(completed.stdout.decode("utf-8", errors="strict"))
        samples.append(int(result["max_rss_bytes"]))
        report = str(result["report"])
        if not expected_report:
            expected_report = report
        elif report != expected_report:
            raise RuntimeError("memory probe report changed between samples")
    mean_rss = sum(samples) // len(samples)
    variance_rss2 = sum((sample - mean_rss) ** 2 for sample in samples) // len(samples)
    print(
        "benchmark_schema=obsidian.process-memory-benchmark.v1 "
        f"python={platform.python_version()} platform={sys.platform}"
    )
    print(
        f"benchmark={name} samples={SAMPLE_COUNT} mean_rss_bytes={mean_rss} "
        f"min_rss_bytes={min(samples)} max_rss_bytes={max(samples)} "
        f"variance_rss2={variance_rss2}"
    )
    if expected_report:
        print(expected_report)
    return 0


def main() -> int:
    if len(sys.argv) == 4 and sys.argv[1] == "--worker":
        return worker(os.path.abspath(sys.argv[2]), sys.argv[3])
    if len(sys.argv) != 4:
        print(
            "usage: measure-process-memory.py <benchmark-name> <binary> <expected-prefix>",
            file=sys.stderr,
        )
        return 2
    binary = os.path.abspath(sys.argv[2])
    if not os.path.isfile(binary) or not os.access(binary, os.X_OK):
        raise RuntimeError("memory benchmark binary is unavailable")
    return measure(sys.argv[1], binary, sys.argv[3])


if __name__ == "__main__":
    raise SystemExit(main())
