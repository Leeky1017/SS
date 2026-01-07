from __future__ import annotations

import argparse
import platform
import sys
import tempfile
import time
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from threading import Lock
from typing import Sequence

_REPO_ROOT = Path(__file__).resolve().parents[1]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from src.infra.file_worker_queue import FileWorkerQueue  # noqa: E402


@dataclass(frozen=True)
class BenchmarkResult:
    queued_jobs: int
    claims: int
    workers: int
    elapsed_seconds: float
    jobs_per_second: float
    claim_p50_ms: float
    claim_p95_ms: float
    claim_p99_ms: float


def _percentile_ms(values_seconds: list[float], p: float) -> float:
    if not values_seconds:
        return 0.0
    sorted_values = sorted(values_seconds)
    index = int(round((p / 100.0) * (len(sorted_values) - 1)))
    index = max(0, min(index, len(sorted_values) - 1))
    return sorted_values[index] * 1000.0


def _run_worker(
    *,
    queue: FileWorkerQueue,
    worker_id: str,
    claim_latencies: list[float],
    lock: Lock,
    claims_done: list[int],
    claims_target: int,
) -> int:
    processed = 0
    while True:
        with lock:
            if claims_done[0] >= claims_target:
                return processed
        t0 = time.perf_counter()
        claim = queue.claim(worker_id=worker_id)
        if claim is None:
            return processed
        claim_latencies.append(time.perf_counter() - t0)
        with lock:
            if claims_done[0] >= claims_target:
                queue.release(claim=claim)
                return processed
            claims_done[0] += 1
        queue.ack(claim=claim)
        processed += 1


def run_benchmark(
    *,
    queue_dir: Path,
    queued_jobs: int,
    claims: int,
    workers: int,
    lease_ttl_seconds: int,
) -> BenchmarkResult:
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=lease_ttl_seconds)
    for i in range(queued_jobs):
        queue.enqueue(job_id=f"job_{i:08d}")

    latencies_by_worker: list[list[float]] = [[] for _ in range(workers)]
    claims_target = min(claims, queued_jobs)
    lock = Lock()
    claims_done = [0]
    start = time.perf_counter()
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [
            pool.submit(
                _run_worker,
                queue=queue,
                worker_id=f"worker-{i}",
                claim_latencies=latencies_by_worker[i],
                lock=lock,
                claims_done=claims_done,
                claims_target=claims_target,
            )
            for i in range(workers)
        ]
        processed_total = sum(f.result() for f in futures)
    elapsed = time.perf_counter() - start

    claim_latencies = [v for worker_vals in latencies_by_worker for v in worker_vals]
    jobs_per_second = (processed_total / elapsed) if elapsed > 0 else 0.0
    return BenchmarkResult(
        queued_jobs=queued_jobs,
        claims=processed_total,
        workers=workers,
        elapsed_seconds=elapsed,
        jobs_per_second=jobs_per_second,
        claim_p50_ms=_percentile_ms(claim_latencies, 50.0),
        claim_p95_ms=_percentile_ms(claim_latencies, 95.0),
        claim_p99_ms=_percentile_ms(claim_latencies, 99.0),
    )


def _print_environment(*, queue_dir: Path) -> None:
    python = sys.version.split()[0]
    print(f"python={python} platform={platform.platform()}")
    print(f"queue_dir={queue_dir}")


def _print_result(result: BenchmarkResult) -> None:
    jobs_per_minute = result.jobs_per_second * 60.0
    print(
        "result "
        f"queued_jobs={result.queued_jobs} claims={result.claims} workers={result.workers} "
        f"elapsed_s={result.elapsed_seconds:.3f} "
        f"jobs_s={result.jobs_per_second:.2f} jobs_min={jobs_per_minute:.1f} "
        f"claim_p50_ms={result.claim_p50_ms:.2f} "
        f"claim_p95_ms={result.claim_p95_ms:.2f} "
        f"claim_p99_ms={result.claim_p99_ms:.2f}"
    )


def _parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Benchmark FileWorkerQueue throughput (claim+ack)."
    )
    parser.add_argument("--queued-jobs", type=int, default=2000)
    parser.add_argument("--claims", type=int, default=None)
    parser.add_argument("--workers", type=int, default=4)
    parser.add_argument("--lease-ttl-seconds", type=int, default=60)
    parser.add_argument("--queue-dir", type=Path, default=None)
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)
    if args.queued_jobs <= 0:
        raise ValueError("--queued-jobs must be positive")
    claims = args.queued_jobs if args.claims is None else args.claims
    if claims <= 0:
        raise ValueError("--claims must be positive")
    if args.workers <= 0:
        raise ValueError("--workers must be positive")

    if args.queue_dir is not None:
        queue_dir = args.queue_dir
        queue_dir.mkdir(parents=True, exist_ok=True)
        _print_environment(queue_dir=queue_dir)
        _print_result(
            run_benchmark(
                queue_dir=queue_dir,
                queued_jobs=args.queued_jobs,
                claims=claims,
                workers=args.workers,
                lease_ttl_seconds=args.lease_ttl_seconds,
            )
        )
        return 0

    tmp_dir: str | None = None
    try:
        with tempfile.TemporaryDirectory(prefix="ss-queue-bench-") as tmp:
            tmp_dir = tmp
            queue_dir = Path(tmp)
            _print_environment(queue_dir=queue_dir)
            result = run_benchmark(
                queue_dir=queue_dir,
                queued_jobs=args.queued_jobs,
                claims=claims,
                workers=args.workers,
                lease_ttl_seconds=args.lease_ttl_seconds,
            )
            _print_result(result)
            return 0
    except KeyboardInterrupt:
        if tmp_dir is not None:
            print(f"interrupted queue_dir={tmp_dir}")
        raise


if __name__ == "__main__":
    raise SystemExit(main())
