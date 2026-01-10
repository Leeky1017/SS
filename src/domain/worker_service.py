from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass
from datetime import datetime
from itertools import repeat
from pathlib import Path
from typing import Callable

from src.domain.audit import AuditContext, AuditEvent, AuditLogger, NoopAuditLogger
from src.domain.do_file_generator import DoFileGenerator
from src.domain.job_store import JobStore
from src.domain.metrics import NoopMetrics, RuntimeMetrics
from src.domain.models import Job, JobStatus
from src.domain.stata_dependency_checker import StataDependencyChecker
from src.domain.stata_runner import RunResult, StataRunner
from src.domain.state_machine import JobStateMachine
from src.domain.worker_claim_handling import ensure_job_claimable, load_job_or_handle
from src.domain.worker_plan_executor import execute_plan
from src.domain.worker_queue import QueueClaim, WorkerQueue
from src.domain.worker_retry import backoff_seconds, normalized_max_attempts
from src.domain.worker_run_attempts import record_attempt_finished, record_attempt_started
from src.infra.exceptions import QueueIOError
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

_SHUTDOWN_RELEASE_CLAIM_EVENT = "SS_WORKER_SHUTDOWN_RELEASE_CLAIM"
_NON_RETRIABLE_ERROR_CODES = {"PLAN_MISSING", "PLAN_INVALID", "INPUTS_MANIFEST_MISSING", "INPUTS_MANIFEST_UNSAFE", "INPUTS_MANIFEST_INVALID", "INPUTS_MANIFEST_READ_FAILED", "DOFILE_PLAN_INVALID", "DOFILE_TEMPLATE_UNSUPPORTED", "DOFILE_INPUTS_MANIFEST_INVALID", "STATA_WORKSPACE_INVALID", "PLAN_COMPOSITION_INVALID", "STATA_INPUTS_UNSAFE", "STATA_DEPENDENCY_MISSING"}  # noqa: E501

_NEVER_STOP = repeat(False).__next__
_NO_DEADLINE = repeat(None).__next__

@dataclass(frozen=True)
class WorkerRetryPolicy:
    max_attempts: int
    backoff_base_seconds: float
    backoff_max_seconds: float

class WorkerService:
    def __init__(
        self,
        *,
        store: JobStore,
        queue: WorkerQueue,
        jobs_dir: Path,
        runner: StataRunner,
        state_machine: JobStateMachine,
        retry: WorkerRetryPolicy,
        do_file_generator: DoFileGenerator | None = None,
        dependency_checker: StataDependencyChecker | None = None,
        metrics: RuntimeMetrics | None = None,
        audit: AuditLogger | None = None,
        clock: Callable[[], datetime] = utc_now,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._store = store
        self._queue = queue
        self._jobs_dir = Path(jobs_dir)
        self._runner = runner
        self._state_machine = state_machine
        self._retry = retry
        self._do_file_generator = do_file_generator
        self._dependency_checker = dependency_checker
        self._metrics = NoopMetrics() if metrics is None else metrics
        self._audit = NoopAuditLogger() if audit is None else audit
        self._clock = clock
        self._sleep = sleep

    def _should_retry(self, *, result: RunResult) -> bool:
        error = result.error
        if error is None:
            return True
        return error.error_code not in _NON_RETRIABLE_ERROR_CODES

    def _emit_audit(
        self,
        *,
        claim: QueueClaim,
        action: str,
        result: str,
        changes: dict[str, object] | None = None,
        metadata: dict[str, object] | None = None,
    ) -> None:
        ctx = AuditContext.system(actor_id=claim.worker_id, source="worker")
        self._audit.emit(
            event=AuditEvent(
                action=action,
                result=result,
                resource_type="job",
                resource_id=claim.job_id,
                job_id=claim.job_id,
                context=ctx,
                changes=changes,
                metadata=metadata,
            )
        )

    def process_next(
        self,
        *,
        worker_id: str,
        stop_requested: Callable[[], bool] | None = None,
        shutdown_deadline: Callable[[], datetime | None] | None = None,
    ) -> bool:
        stop = _NEVER_STOP if stop_requested is None else stop_requested
        deadline = _NO_DEADLINE if shutdown_deadline is None else shutdown_deadline
        if stop():
            return False
        claim = self._queue.claim(worker_id=worker_id)
        if claim is None:
            return False
        if stop():
            self._release_claim_on_shutdown(
                claim=claim,
                event="SS_WORKER_SHUTDOWN_RELEASE_UNPROCESSED_CLAIM",
            )
            return False
        self.process_claim(claim=claim, stop_requested=stop, shutdown_deadline=deadline)
        return True

    def process_claim(
        self,
        *,
        claim: QueueClaim,
        stop_requested: Callable[[], bool] | None = None,
        shutdown_deadline: Callable[[], datetime | None] | None = None,
    ) -> None:
        stop = _NEVER_STOP if stop_requested is None else stop_requested
        deadline = _NO_DEADLINE if shutdown_deadline is None else shutdown_deadline
        if stop():
            self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
            return
        job = load_job_or_handle(
            store=self._store,
            claim=claim,
            ack=self._ack,
            release=self._release,
        )
        if job is None:
            return
        if stop():
            self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
            return
        if not ensure_job_claimable(
            store=self._store,
            state_machine=self._state_machine,
            job=job,
            claim=claim,
            ack=self._ack,
            release=self._release,
            emit_audit=self._emit_audit,
        ):
            return
        self._metrics.worker_inflight_inc(worker_id=claim.worker_id)
        try:
            self._run_job_with_retries(
                job=job,
                claim=claim,
                stop_requested=stop,
                shutdown_deadline=deadline,
            )
        finally:
            self._metrics.worker_inflight_dec(worker_id=claim.worker_id)

    def _run_job_with_retries(
        self,
        *,
        job: Job,
        claim: QueueClaim,
        stop_requested: Callable[[], bool],
        shutdown_deadline: Callable[[], datetime | None],
    ) -> None:
        max_attempts = normalized_max_attempts(self._retry.max_attempts)
        attempt = len(job.runs) + 1
        while attempt <= max_attempts:
            if stop_requested():
                self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
                return
            run_id = uuid.uuid4().hex
            record_attempt_started(
                job=job,
                run_id=run_id,
                attempt=attempt,
                store=self._store,
                clock=self._clock,
            )
            result = execute_plan(
                job=job,
                run_id=run_id,
                jobs_dir=self._jobs_dir,
                runner=self._runner,
                dependency_checker=self._dependency_checker,
                shutdown_deadline=shutdown_deadline(),
                clock=self._clock,
                do_file_generator=self._do_file_generator,
            )
            record_attempt_finished(
                job=job,
                run_id=run_id,
                result=result,
                clock=self._clock,
            )
            self._store.save(tenant_id=claim.tenant_id, job=job)

            if result.ok:
                self._finish_job(job=job, status=JobStatus.SUCCEEDED, claim=claim)
                self._ack(claim)
                return

            if not self._should_retry(result=result):
                logger.info(
                    "SS_WORKER_RETRY_SKIPPED_NON_RETRIABLE",
                    extra={
                        "job_id": job.job_id,
                        "run_id": run_id,
                        "error_code": None if result.error is None else result.error.error_code,
                    },
                )
                self._finish_job(job=job, status=JobStatus.FAILED, claim=claim)
                self._ack(claim)
                return

            if attempt >= max_attempts:
                self._finish_job(job=job, status=JobStatus.FAILED, claim=claim)
                self._ack(claim)
                return

            if stop_requested():
                self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
                return

            backoff = backoff_seconds(
                attempt=attempt,
                base_seconds=self._retry.backoff_base_seconds,
                max_seconds=self._retry.backoff_max_seconds,
            )
            logger.info(
                "SS_WORKER_RETRY_BACKOFF",
                extra={"job_id": job.job_id, "attempt": attempt, "sleep_seconds": backoff},
            )
            self._sleep(backoff)
            attempt += 1

    def _finish_job(self, *, job: Job, status: JobStatus, claim: QueueClaim) -> None:
        from_status = job.status.value
        if self._state_machine.ensure_transition(
            job_id=job.job_id,
            from_status=job.status,
            to_status=status,
        ):
            job.status = status
        self._store.save(tenant_id=claim.tenant_id, job=job)
        logger.info("SS_WORKER_JOB_DONE", extra={"job_id": job.job_id, "status": job.status.value})
        self._metrics.record_job_finished(status=status.value)
        if from_status != job.status.value:
            self._emit_audit(
                claim=claim,
                action="job.status.transition",
                result="success",
                changes={"from_status": from_status, "to_status": job.status.value},
            )

    def _release_claim_on_shutdown(self, *, claim: QueueClaim, event: str) -> None:
        logger.info(
            event,
            extra={"job_id": claim.job_id, "claim_id": claim.claim_id},
        )
        self._release(claim)

    def _ack(self, claim: QueueClaim) -> None:
        try:
            self._queue.ack(claim=claim)
        except QueueIOError as e:
            logger.warning(
                "SS_WORKER_QUEUE_ACK_FAILED",
                extra={
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "error_code": e.error_code,
                },
            )
            raise

    def _release(self, claim: QueueClaim) -> None:
        try:
            self._queue.release(claim=claim)
        except QueueIOError as e:
            logger.warning(
                "SS_WORKER_QUEUE_RELEASE_FAILED",
                extra={
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "error_code": e.error_code,
                },
            )
            raise
