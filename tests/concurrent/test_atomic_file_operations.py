from __future__ import annotations

import threading
from concurrent.futures import ThreadPoolExecutor

from src.domain.models import JOB_SCHEMA_VERSION_CURRENT
from src.infra.job_store import JobStore


def test_job_store_save_and_load_under_contention_never_reads_partial_json(
    job_service,
    store: JobStore,
) -> None:
    job = job_service.create_job(requirement="base")
    stop = threading.Event()

    def _writer() -> None:
        current = store.load(job.job_id)
        for i in range(200):
            current.requirement = f"v-{i}"
            store.save(current)
        stop.set()

    def _reader() -> int:
        reads = 0
        while not stop.is_set() and reads < 1000:
            loaded = store.load(job.job_id)
            assert loaded.schema_version == JOB_SCHEMA_VERSION_CURRENT
            reads += 1
        return reads

    with ThreadPoolExecutor(max_workers=2) as pool:
        writer_future = pool.submit(_writer)
        reader_future = pool.submit(_reader)
        writer_future.result()
        reader_future.result()
