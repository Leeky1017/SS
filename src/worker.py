from __future__ import annotations

import logging
import os
import shutil
import signal
import threading
from dataclasses import dataclass
from datetime import datetime, timedelta
from pathlib import Path
from types import FrameType

from opentelemetry.trace import get_tracer

from src.config import Config, load_config
from src.domain.do_file_generator import DoFileGenerator
from src.domain.output_formatter_service import OutputFormatterService
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.audit_logger import LoggingAuditLogger
from src.infra.exceptions import SSError
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store_factory import build_job_store
from src.infra.local_stata_dependency_checker import LocalStataDependencyChecker
from src.infra.local_stata_runner import LocalStataRunner
from src.infra.logging_config import configure_logging
from src.infra.prometheus_metrics import PrometheusMetrics
from src.infra.tracing import configure_tracing, context_from_traceparent
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


@dataclass
class _ShutdownState:
    requested: threading.Event
    deadline: datetime | None


def _start_metrics(*, worker_id: str, port: int) -> PrometheusMetrics:
    metrics = PrometheusMetrics()
    metrics.set_worker_up(worker_id=worker_id, up=True)
    if port > 0:
        metrics.start_http_server(port=port)
        logger.info(
            "SS_WORKER_METRICS_SERVER_STARTED",
            extra={"worker_id": worker_id, "port": port},
        )
    return metrics


def _install_shutdown_handlers(*, worker_id: str, grace_seconds: float) -> _ShutdownState:
    state = _ShutdownState(requested=threading.Event(), deadline=None)

    def _request_shutdown(signum: int, _frame: FrameType | None) -> None:
        if state.requested.is_set():
            return
        state.requested.set()
        state.deadline = utc_now() + timedelta(seconds=grace_seconds)
        try:
            signal_name = signal.Signals(signum).name
        except ValueError:
            signal_name = str(signum)
        logger.info(
            "SS_WORKER_SHUTDOWN_REQUESTED",
            extra={"worker_id": worker_id, "signal": signal_name, "grace_seconds": grace_seconds},
        )

    signal.signal(signal.SIGTERM, _request_shutdown)
    signal.signal(signal.SIGINT, _request_shutdown)
    return state


def _fail_worker_startup(
    *,
    worker_id: str,
    error_code: str,
    message: str,
    context: dict[str, object],
) -> None:
    logger.error(
        "SS_WORKER_STARTUP_FAILED",
        extra={"worker_id": worker_id, "error_code": error_code, **context},
    )
    raise SSError(error_code=error_code, message=message, status_code=500)


def _validate_stata_cmd_or_raise(*, worker_id: str, stata_cmd: tuple[str, ...]) -> None:
    executable = str(stata_cmd[0]).strip()
    executable_path = Path(executable)
    looks_like_path = executable_path.is_absolute() or executable_path.parent != Path(".")
    if looks_like_path:
        resolved = executable_path
        if not resolved.is_absolute():
            resolved = (Path.cwd() / resolved).resolve()
        if not resolved.is_file():
            _fail_worker_startup(
                worker_id=worker_id,
                error_code="STATA_CMD_INVALID",
                message=f"SS_STATA_CMD executable not found: {resolved}",
                context={
                    "stata_cmd": list(stata_cmd),
                    "reason": "not_found",
                    "resolved": str(resolved),
                },
            )
        if not os.access(str(resolved), os.X_OK):
            _fail_worker_startup(
                worker_id=worker_id,
                error_code="STATA_CMD_INVALID",
                message=f"SS_STATA_CMD executable is not executable: {resolved}",
                context={
                    "stata_cmd": list(stata_cmd),
                    "reason": "not_executable",
                    "resolved": str(resolved),
                },
            )
        return
    if shutil.which(executable) is None:
        _fail_worker_startup(
            worker_id=worker_id,
            error_code="STATA_CMD_INVALID",
            message=f"SS_STATA_CMD executable not found in PATH: {executable}",
            context={
                "stata_cmd": list(stata_cmd),
                "reason": "not_in_path",
                "executable": executable,
            },
        )


def _require_stata_cmd(*, worker_id: str, stata_cmd: tuple[str, ...]) -> tuple[str, ...]:
    if not stata_cmd:
        _fail_worker_startup(
            worker_id=worker_id,
            error_code="STATA_CMD_NOT_CONFIGURED",
            message="SS_STATA_CMD is required to start worker (no runtime fake runner fallback)",
            context={"missing": ["SS_STATA_CMD"]},
        )
    _validate_stata_cmd_or_raise(worker_id=worker_id, stata_cmd=stata_cmd)
    return stata_cmd


def _build_runner(
    *,
    worker_id: str,
    jobs_dir: Path,
    stata_cmd: tuple[str, ...],
) -> LocalStataRunner:
    configured = _require_stata_cmd(worker_id=worker_id, stata_cmd=stata_cmd)
    runner = LocalStataRunner(jobs_dir=jobs_dir, stata_cmd=configured)
    logger.info(
        "SS_WORKER_RUNNER_SELECTED",
        extra={"worker_id": worker_id, "runner": "local", "stata_cmd": list(configured)},
    )
    return runner


def _wire_do_template_library(*, library_dir: Path) -> FileSystemDoTemplateRepository:
    catalog = FileSystemDoTemplateCatalog(library_dir=library_dir)
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    logger.info(
        "SS_DO_TEMPLATE_LIBRARY_WIRED",
        extra={
            "library_dir": str(library_dir),
            "families": len(catalog.list_families()),
            "templates": len(repo.list_template_ids()),
        },
    )
    return repo


def _build_worker_service(
    *,
    config: Config,
    metrics: PrometheusMetrics,
) -> tuple[WorkerService, FileWorkerQueue]:
    store = build_job_store(config=config)
    queue = FileWorkerQueue(
        queue_dir=config.queue_dir,
        lease_ttl_seconds=config.queue_lease_ttl_seconds,
    )
    runner = _build_runner(
        worker_id=config.worker_id,
        jobs_dir=config.jobs_dir,
        stata_cmd=config.stata_cmd,
    )
    dependency_checker = LocalStataDependencyChecker(
        jobs_dir=config.jobs_dir,
        stata_cmd=_require_stata_cmd(worker_id=config.worker_id, stata_cmd=config.stata_cmd),
    )
    do_template_repo = _wire_do_template_library(library_dir=config.do_template_library_dir)
    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=config.jobs_dir,
        runner=runner,
        output_formatter=OutputFormatterService(jobs_dir=config.jobs_dir),
        dependency_checker=dependency_checker,
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(
            max_attempts=config.worker_max_attempts,
            backoff_base_seconds=config.worker_retry_backoff_base_seconds,
            backoff_max_seconds=config.worker_retry_backoff_max_seconds,
        ),
        do_file_generator=DoFileGenerator(do_template_repo=do_template_repo),
        metrics=metrics,
        audit=LoggingAuditLogger(),
    )
    return service, queue


def _run_worker_loop(
    *,
    worker_id: str,
    config: Config,
    service: WorkerService,
    queue: FileWorkerQueue,
    shutdown: _ShutdownState,
) -> None:
    def _stop_requested() -> bool:
        return shutdown.requested.is_set()

    def _shutdown_deadline() -> datetime | None:
        return shutdown.deadline

    while not shutdown.requested.is_set():
        claim = queue.claim(worker_id=worker_id)
        if claim is None:
            shutdown.requested.wait(timeout=config.worker_idle_sleep_seconds)
            continue

        ctx = None if claim.traceparent is None else context_from_traceparent(claim.traceparent)
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


def main() -> None:
    config = load_config()
    configure_logging(log_level=config.log_level)
    configure_tracing(config=config, component="worker")
    metrics = _start_metrics(worker_id=config.worker_id, port=config.worker_metrics_port)
    try:
        shutdown = _install_shutdown_handlers(
            worker_id=config.worker_id,
            grace_seconds=config.worker_shutdown_grace_seconds,
        )
        service, queue = _build_worker_service(config=config, metrics=metrics)
        logger.info("SS_WORKER_STARTUP", extra={"worker_id": config.worker_id})
        _run_worker_loop(
            worker_id=config.worker_id,
            config=config,
            service=service,
            queue=queue,
            shutdown=shutdown,
        )
    finally:
        metrics.set_worker_up(worker_id=config.worker_id, up=False)
        logger.info("SS_WORKER_SHUTDOWN_COMPLETE", extra={"worker_id": config.worker_id})


if __name__ == "__main__":
    try:
        main()
    except SSError as e:
        logger.error(
            "SS_WORKER_FATAL",
            extra={"error_code": e.error_code, "error_message": e.message},
        )
        raise SystemExit(1) from e
    except KeyboardInterrupt:
        raise SystemExit(0) from None
