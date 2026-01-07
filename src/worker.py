from __future__ import annotations

import logging
import signal
import threading
from datetime import datetime, timedelta
from types import FrameType

from src.config import load_config
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.fake_stata_runner import FakeStataRunner
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.logging_config import configure_logging
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


def main() -> None:
    config = load_config()
    configure_logging(log_level=config.log_level)

    shutdown_requested = threading.Event()
    shutdown_deadline: datetime | None = None

    def _request_shutdown(signum: int, _frame: FrameType | None) -> None:
        nonlocal shutdown_deadline
        if shutdown_requested.is_set():
            return
        shutdown_requested.set()
        shutdown_deadline = utc_now() + timedelta(seconds=config.worker_shutdown_grace_seconds)
        try:
            signal_name = signal.Signals(signum).name
        except ValueError:
            signal_name = str(signum)
        logger.info(
            "SS_WORKER_SHUTDOWN_REQUESTED",
            extra={
                "worker_id": config.worker_id,
                "signal": signal_name,
                "grace_seconds": config.worker_shutdown_grace_seconds,
            },
        )

    signal.signal(signal.SIGTERM, _request_shutdown)
    signal.signal(signal.SIGINT, _request_shutdown)

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

    logger.info("SS_WORKER_STARTUP", extra={"worker_id": config.worker_id})

    def _stop_requested() -> bool:
        return shutdown_requested.is_set()

    def _shutdown_deadline() -> datetime | None:
        return shutdown_deadline

    while not shutdown_requested.is_set():
        processed = service.process_next(
            worker_id=config.worker_id,
            stop_requested=_stop_requested,
            shutdown_deadline=_shutdown_deadline,
        )
        if processed:
            continue
        shutdown_requested.wait(timeout=config.worker_idle_sleep_seconds)

    logger.info("SS_WORKER_SHUTDOWN_COMPLETE", extra={"worker_id": config.worker_id})


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit(0) from None
