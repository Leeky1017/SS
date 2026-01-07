from __future__ import annotations

import threading
from concurrent.futures import ThreadPoolExecutor

from src.infra.exceptions import JobVersionConflictError
from src.infra.job_store import JobStore


def test_save_with_concurrent_writers_detects_version_conflict(
    job_service,
    store: JobStore,
) -> None:
    job = job_service.create_job(requirement="base")
    first = store.load(job.job_id)
    second = store.load(job.job_id)

    barrier = threading.Barrier(2)

    def _save(value: str) -> None:
        barrier.wait()
        if value == "first":
            first.requirement = value
            store.save(first)
        else:
            second.requirement = value
            store.save(second)

    with ThreadPoolExecutor(max_workers=2) as pool:
        future_a = pool.submit(_save, "first")
        future_b = pool.submit(_save, "second")

        outcomes: list[str] = []
        conflicts = 0
        for future in (future_a, future_b):
            try:
                future.result()
                outcomes.append("ok")
            except JobVersionConflictError:
                conflicts += 1
                outcomes.append("conflict")

    assert conflicts == 1
    assert sorted(outcomes) == ["conflict", "ok"]
    persisted = store.load(job.job_id)
    assert persisted.requirement in {"first", "second"}
