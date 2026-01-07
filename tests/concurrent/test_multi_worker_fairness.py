from __future__ import annotations

import threading
from collections import Counter
from concurrent.futures import ThreadPoolExecutor


def test_multi_worker_claims_each_job_exactly_once(
    create_queued_job,
    queue,
    queue_dir,
) -> None:
    job_ids = [create_queued_job(f"req-{i}") for i in range(30)]

    processed: list[str] = []
    processed_lock = threading.Lock()
    barrier = threading.Barrier(6)

    def _work(worker_id: str) -> None:
        barrier.wait()
        while True:
            claim = queue.claim(worker_id=worker_id)
            if claim is None:
                return
            with processed_lock:
                processed.append(claim.job_id)
            queue.ack(claim=claim)

    with ThreadPoolExecutor(max_workers=6) as pool:
        futures = []
        for i in range(6):
            futures.append(pool.submit(_work, f"worker-{i}"))
        for future in futures:
            future.result()

    counts = Counter(processed)
    assert len(processed) == len(job_ids)
    assert set(processed) == set(job_ids)
    assert all(value == 1 for value in counts.values())
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []
