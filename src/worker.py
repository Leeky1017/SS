from __future__ import annotations

import time

from src.config import load_config
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.fake_stata_runner import FakeStataRunner
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.logging_config import configure_logging


def main() -> None:
    config = load_config()
    configure_logging(log_level=config.log_level)

    store = JobStore(jobs_dir=config.jobs_dir)
    queue = FileWorkerQueue(
        queue_dir=config.queue_dir,
        lease_ttl_seconds=config.queue_lease_ttl_seconds,
    )
    runner = FakeStataRunner(jobs_dir=config.jobs_dir)
    service = WorkerService(
        store=store,
        queue=queue,
        runner=runner,
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(
            max_attempts=config.worker_max_attempts,
            backoff_base_seconds=config.worker_retry_backoff_base_seconds,
            backoff_max_seconds=config.worker_retry_backoff_max_seconds,
        ),
    )

    while True:
        processed = service.process_next(worker_id=config.worker_id)
        if processed:
            continue
        time.sleep(config.worker_idle_sleep_seconds)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit(0) from None
