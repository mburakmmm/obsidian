#!/usr/bin/env python3
import os
import platform
import subprocess
import sys
import time

WARMUP_ITERATIONS = 10
ITERATIONS = 50
SAMPLE_COUNT = 7
NANOSECONDS_PER_SECOND = 1_000_000_000


def run_once(binary: str) -> None:
    completed = subprocess.run(
        [binary],
        stdin=subprocess.DEVNULL,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if completed.returncode != 0:
        raise RuntimeError("startup probe exited unsuccessfully")
    if completed.stdout or completed.stderr:
        raise RuntimeError("startup probe emitted unexpected output")


def measure(binary: str) -> tuple[int, int, int, int]:
    for _ in range(WARMUP_ITERATIONS):
        run_once(binary)
    samples: list[int] = []
    for _ in range(SAMPLE_COUNT):
        started_ns = time.monotonic_ns()
        for _ in range(ITERATIONS):
            run_once(binary)
        elapsed_ns = time.monotonic_ns() - started_ns
        sample_ns = elapsed_ns // ITERATIONS
        if sample_ns < 1:
            raise RuntimeError("startup benchmark resolution is insufficient")
        samples.append(sample_ns)
    mean_ns = sum(samples) // len(samples)
    variance_ns2 = sum((sample - mean_ns) ** 2 for sample in samples) // len(samples)
    return mean_ns, min(samples), max(samples), variance_ns2


def report(name: str, binary: str) -> None:
    mean_ns, minimum_ns, maximum_ns, variance_ns2 = measure(binary)
    operations_per_second = NANOSECONDS_PER_SECOND // mean_ns
    print(
        f"benchmark={name} iterations={ITERATIONS} samples={SAMPLE_COUNT} "
        f"mean_ns={mean_ns} min_ns={minimum_ns} max_ns={maximum_ns} "
        f"variance_ns2={variance_ns2} ops_per_second={operations_per_second}"
    )


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: measure-process-startup.py <empty-binary> <logger-binary>", file=sys.stderr)
        return 2
    empty_binary = os.path.abspath(sys.argv[1])
    logger_binary = os.path.abspath(sys.argv[2])
    for binary in (empty_binary, logger_binary):
        if not os.path.isfile(binary) or not os.access(binary, os.X_OK):
            raise RuntimeError("startup benchmark binary is unavailable")
    print(
        "benchmark_schema=obsidian.process-startup-benchmark.v1 "
        f"warmup={WARMUP_ITERATIONS} python={platform.python_version()}"
    )
    report("process_startup_empty", empty_binary)
    report("process_startup_logger", logger_binary)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
