from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Callable

from src.domain.audit import AuditContext, AuditEvent, AuditLogger, NoopAuditLogger
from src.domain.job_store import JobStore
from src.domain.metrics import NoopMetrics, RuntimeMetrics
from src.domain.models import Job, JobStatus
from src.domain.stata_runner import StataRunner
from src.domain.state_machine import JobStateMachine
from src.domain.worker_plan_executor import execute_plan
from src.domain.worker_queue import QueueClaim, WorkerQueue
from src.domain.worker_retry import backoff_seconds, normalized_max_attempts
from src.domain.worker_run_attempts import record_attempt_finished, record_attempt_started
from src.infra.exceptions import (
    JobDataCorruptedError,
    JobNotFoundError,
    JobStoreIOError,
    QueueIOError,
)
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

StopRequested = Callable[[], bool]
ShutdownDeadline = Callable[[], datetime | None]

_SHUTDOWN_RELEASE_CLAIM_EVENT = "SS_WORKER_SHUTDOWN_RELEASE_CLAIM"


def _never_stop() -> bool:
    return False


def _no_deadline() -> datetime | None:
    return None


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
        runner: StataRunner,
        state_machine: JobStateMachine,
        retry: WorkerRetryPolicy,
        metrics: RuntimeMetrics | None = None,
        audit: AuditLogger | None = None,
        clock: Callable[[], datetime] = utc_now,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._store = store
        self._queue = queue
        self._runner = runner
        self._state_machine = state_machine
        self._retry = retry
        self._metrics = NoopMetrics() if metrics is None else metrics
        self._audit = NoopAuditLogger() if audit is None else audit
        self._clock = clock
        self._sleep = sleep

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
        stop_requested: StopRequested | None = None,
        shutdown_deadline: ShutdownDeadline | None = None,
    ) -> bool:
        stop = _never_stop if stop_requested is None else stop_requested
        deadline = _no_deadline if shutdown_deadline is None else shutdown_deadline
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
        stop_requested: StopRequested | None = None,
        shutdown_deadline: ShutdownDeadline | None = None,
    ) -> None:
        stop = _never_stop if stop_requested is None else stop_requested
        deadline = _no_deadline if shutdown_deadline is None else shutdown_deadline
        if stop():
            self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
            return
        job = self._load_job_or_handle(claim=claim)
        if job is None:
            return
        if stop():
            self._release_claim_on_shutdown(claim=claim, event=_SHUTDOWN_RELEASE_CLAIM_EVENT)
            return
        if not self._ensure_job_claimable(job=job, claim=claim):
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

    def _load_job_or_handle(self, *, claim: QueueClaim) -> Job | None:
        try:
            return self._store.load(tenant_id=claim.tenant_id, job_id=claim.job_id)
        except JobNotFoundError:
            logger.warning(
                "SS_WORKER_JOB_NOT_FOUND",
                extra={
                    "tenant_id": claim.tenant_id,
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "worker_id": claim.worker_id,
                },
            )
            self._ack(claim=claim)
            return None
        except JobDataCorruptedError:
            logger.warning(
                "SS_WORKER_JOB_CORRUPTED",
                extra={
                    "tenant_id": claim.tenant_id,
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "worker_id": claim.worker_id,
                },
            )
            self._ack(claim=claim)
            return None
        except JobStoreIOError as e:
            logger.warning(
                "SS_WORKER_JOB_LOAD_FAILED",
                extra={
                    "tenant_id": claim.tenant_id,
                    "job_id": claim.job_id,
                    "claim_id": claim.claim_id,
                    "worker_id": claim.worker_id,
                    "error_code": e.error_code,
                },
            )
            self._release(claim=claim)
            return None

    def _ensure_job_claimable(self, *, job: Job, claim: QueueClaim) -> bool:
        if job.status == JobStatus.QUEUED:
            if self._state_machine.ensure_transition(
                job_id=job.job_id,
                from_status=job.status,
                to_status=JobStatus.RUNNING,
            ):
                from_status = job.status.value
                job.status = JobStatus.RUNNING
                self._store.save(tenant_id=claim.tenant_id, job=job)
                self._emit_audit(
                    claim=claim,
                    action="job.status.transition",
                    result="success",
                    changes={"from_status": from_status, "to_status": job.status.value},
                    metadata={"claim_id": claim.claim_id},
                )
            return True

        if job.status == JobStatus.RUNNING:
            return True

        if job.status in {JobStatus.SUCCEEDED, JobStatus.FAILED}:
            logger.info(
                "SS_WORKER_JOB_ALREADY_DONE",
                extra={
                    "job_id": job.job_id,
                    "status": job.status.value,
                    "claim_id": claim.claim_id,
                },
            )
            self._ack(claim=claim)
            return False

        logger.warning(
            "SS_WORKER_JOB_NOT_READY",
            extra={"job_id": job.job_id, "status": job.status.value, "claim_id": claim.claim_id},
        )
        self._release(claim=claim)
        return False

    def _run_job_with_retries(
        self,
        *,
        job: Job,
        claim: QueueClaim,
        stop_requested: StopRequested,
        shutdown_deadline: ShutdownDeadline,
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
                runner=self._runner,
                shutdown_deadline=shutdown_deadline(),
                clock=self._clock,
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
                self._ack(claim=claim)
                return

            if attempt >= max_attempts:
                self._finish_job(job=job, status=JobStatus.FAILED, claim=claim)
                self._ack(claim=claim)
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
        self._release(claim=claim)

    def _ack(self, *, claim: QueueClaim) -> None:
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

    def _release(self, *, claim: QueueClaim) -> None:
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
