from __future__ import annotations

import logging
import signal
import threading
from datetime import datetime, timedelta
from types import FrameType

from opentelemetry.trace import get_tracer

from src.config import load_config
from src.domain.stata_runner import StataRunner
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.audit_logger import LoggingAuditLogger
from src.infra.fake_stata_runner import FakeStataRunner
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store_factory import build_job_store
from src.infra.local_stata_runner import LocalStataRunner
from src.infra.logging_config import configure_logging
from src.infra.prometheus_metrics import PrometheusMetrics
from src.infra.tracing import configure_tracing, context_from_traceparent
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


def main() -> None:
    config = load_config()
    configure_logging(log_level=config.log_level)
    configure_tracing(config=config, component="worker")

    metrics = PrometheusMetrics()
    metrics.set_worker_up(worker_id=config.worker_id, up=True)
    if config.worker_metrics_port > 0:
        metrics.start_http_server(port=config.worker_metrics_port)
        logger.info(
            "SS_WORKER_METRICS_SERVER_STARTED",
            extra={"worker_id": config.worker_id, "port": config.worker_metrics_port},
        )

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

    store = build_job_store(config=config)
    queue = FileWorkerQueue(
        queue_dir=config.queue_dir,
        lease_ttl_seconds=config.queue_lease_ttl_seconds,
    )
    runner: StataRunner
    if config.stata_cmd:
        runner = LocalStataRunner(jobs_dir=config.jobs_dir, stata_cmd=config.stata_cmd)
        logger.info(
            "SS_WORKER_RUNNER_SELECTED",
            extra={
                "worker_id": config.worker_id,
                "runner": "local",
                "stata_cmd": list(config.stata_cmd),
            },
        )
    else:
        runner = FakeStataRunner(jobs_dir=config.jobs_dir)
        logger.info(
            "SS_WORKER_RUNNER_SELECTED",
            extra={"worker_id": config.worker_id, "runner": "fake"},
        )
    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=config.jobs_dir,
        runner=runner,
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(
            max_attempts=config.worker_max_attempts,
            backoff_base_seconds=config.worker_retry_backoff_base_seconds,
            backoff_max_seconds=config.worker_retry_backoff_max_seconds,
        ),
        metrics=metrics,
        audit=LoggingAuditLogger(),
    )

    logger.info("SS_WORKER_STARTUP", extra={"worker_id": config.worker_id})

    def _stop_requested() -> bool:
        return shutdown_requested.is_set()

    def _shutdown_deadline() -> datetime | None:
        return shutdown_deadline

    try:
        while not shutdown_requested.is_set():
            claim = queue.claim(worker_id=config.worker_id)
            if claim is None:
                processed = False
            else:
                ctx = None
                if claim.traceparent is not None:
                    ctx = context_from_traceparent(claim.traceparent)
                tracer = get_tracer(__name__)
                with tracer.start_as_current_span("ss.queue.claim", context=ctx) as span:
                    span.set_attribute("ss.job_id", claim.job_id)
                    span.set_attribute("ss.claim_id", claim.claim_id)
                    span.set_attribute("ss.worker_id", claim.worker_id)
                    service.process_claim(
                        claim=claim,
                        stop_requested=_stop_requested,
                        shutdown_deadline=_shutdown_deadline,
                    )
                processed = True
            if processed:
                continue
            shutdown_requested.wait(timeout=config.worker_idle_sleep_seconds)
    finally:
        metrics.set_worker_up(worker_id=config.worker_id, up=False)
        logger.info("SS_WORKER_SHUTDOWN_COMPLETE", extra={"worker_id": config.worker_id})


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        raise SystemExit(0) from None
