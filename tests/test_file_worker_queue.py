from __future__ import annotations

import json
import threading
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from pathlib import Path

from src.infra.file_worker_queue import FileWorkerQueue


def test_enqueue_called_twice_does_not_duplicate_queue_entry(tmp_path: Path) -> None:
    # Arrange
    queue_dir = tmp_path / "queue"
    now = datetime(2026, 1, 6, tzinfo=timezone.utc)
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60, clock=lambda: now)
    job_id = "job_test"

    # Act
    queue.enqueue(job_id=job_id)
    queue.enqueue(job_id=job_id)

    # Assert
    assert len(list((queue_dir / "queued").glob("*.json"))) == 1


def test_claim_with_two_workers_competing_returns_single_claim(tmp_path: Path) -> None:
    # Arrange
    queue_dir = tmp_path / "queue"
    now = datetime(2026, 1, 6, tzinfo=timezone.utc)
    queue_a = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60, clock=lambda: now)
    queue_b = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60, clock=lambda: now)
    job_id = "job_test"
    queue_a.enqueue(job_id=job_id)

    barrier = threading.Barrier(2)

    def _claim(queue: FileWorkerQueue, worker_id: str):
        barrier.wait()
        return queue.claim(worker_id=worker_id)

    # Act
    with ThreadPoolExecutor(max_workers=2) as pool:
        future_a = pool.submit(_claim, queue_a, "worker-a")
        future_b = pool.submit(_claim, queue_b, "worker-b")
        claim_a = future_a.result()
        claim_b = future_b.result()

    # Assert
    claims = [claim for claim in (claim_a, claim_b) if claim is not None]
    assert len(claims) == 1
    assert claims[0].job_id == job_id
    assert len(list((queue_dir / "claimed").glob("*.json"))) == 1
    assert list((queue_dir / "queued").glob("*.json")) == []


def test_claim_with_expired_lease_reclaims_job(tmp_path: Path) -> None:
    # Arrange
    queue_dir = tmp_path / "queue"
    now_0 = datetime(2026, 1, 6, tzinfo=timezone.utc)
    now_1 = now_0 + timedelta(seconds=2)
    queue_1 = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=1, clock=lambda: now_0)
    queue_2 = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=1, clock=lambda: now_1)
    job_id = "job_test"
    queue_1.enqueue(job_id=job_id)

    # Act
    claim_1 = queue_1.claim(worker_id="worker-1")
    claim_2 = queue_2.claim(worker_id="worker-2")

    # Assert
    assert claim_1 is not None
    assert claim_2 is not None
    assert claim_2.job_id == job_id
    assert claim_2.worker_id == "worker-2"
    claimed_files = list((queue_dir / "claimed").glob("*.json"))
    assert len(claimed_files) == 1
    assert list((queue_dir / "queued").glob("*.json")) == []
    record = json.loads(claimed_files[0].read_text(encoding="utf-8"))
    assert record.get("worker_id") == "worker-2"
