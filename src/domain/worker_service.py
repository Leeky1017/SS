from __future__ import annotations

import logging
import time
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import Callable

from src.domain.models import Job, JobStatus, PlanStep, PlanStepType, RunAttempt
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.domain.state_machine import JobStateMachine
from src.domain.worker_queue import QueueClaim, WorkerQueue
from src.infra.exceptions import (
    JobDataCorruptedError,
    JobNotFoundError,
    JobStoreIOError,
    QueueIOError,
)
from src.infra.job_store import JobStore
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


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
        clock: Callable[[], datetime] = utc_now,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._store = store
        self._queue = queue
        self._runner = runner
        self._state_machine = state_machine
        self._retry = retry
        self._clock = clock
        self._sleep = sleep

    def process_next(self, *, worker_id: str) -> bool:
        claim = self._queue.claim(worker_id=worker_id)
        if claim is None:
            return False
        self.process_claim(claim=claim)
        return True

    def process_claim(self, *, claim: QueueClaim) -> None:
        job = self._load_job_or_handle(claim=claim)
        if job is None:
            return
        if not self._ensure_job_claimable(job=job, claim=claim):
            return
        self._run_job_with_retries(job=job, claim=claim)

    def _load_job_or_handle(self, *, claim: QueueClaim) -> Job | None:
        try:
            return self._store.load(claim.job_id)
        except JobNotFoundError:
            logger.warning(
                "SS_WORKER_JOB_NOT_FOUND",
                extra={
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
                job.status = JobStatus.RUNNING
                self._store.save(job)
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

    def _run_job_with_retries(self, *, job: Job, claim: QueueClaim) -> None:
        max_attempts = self._normalized_max_attempts()
        attempt = len(job.runs) + 1
        while attempt <= max_attempts:
            run_id = uuid.uuid4().hex
            self._record_attempt_started(job=job, run_id=run_id, attempt=attempt)
            result = self._execute_plan(job=job, run_id=run_id)
            self._record_attempt_finished(job=job, run_id=run_id, result=result)
            self._store.save(job)

            if result.ok:
                self._finish_job(job=job, status=JobStatus.SUCCEEDED)
                self._ack(claim=claim)
                return

            if attempt >= max_attempts:
                self._finish_job(job=job, status=JobStatus.FAILED)
                self._ack(claim=claim)
                return

            backoff = self._backoff_seconds(attempt=attempt)
            logger.info(
                "SS_WORKER_RETRY_BACKOFF",
                extra={"job_id": job.job_id, "attempt": attempt, "sleep_seconds": backoff},
            )
            self._sleep(backoff)
            attempt += 1

    def _record_attempt_started(self, *, job: Job, run_id: str, attempt: int) -> None:
        started_at = self._clock().isoformat()
        job.runs.append(
            RunAttempt(
                run_id=run_id,
                attempt=attempt,
                status="running",
                started_at=started_at,
                ended_at=None,
                artifacts=[],
            )
        )
        self._store.save(job)
        logger.info(
            "SS_WORKER_ATTEMPT_START",
            extra={"job_id": job.job_id, "run_id": run_id, "attempt": attempt},
        )

    def _record_attempt_finished(self, *, job: Job, run_id: str, result: RunResult) -> None:
        ended_at = self._clock().isoformat()
        attempt = self._find_attempt(job=job, run_id=run_id)
        attempt.ended_at = ended_at
        attempt.status = "succeeded" if result.ok else "failed"
        attempt.artifacts = list(result.artifacts)
        self._index_artifacts(job=job, result=result)
        logger.info(
            "SS_WORKER_ATTEMPT_DONE",
            extra={"job_id": job.job_id, "run_id": run_id, "ok": result.ok},
        )

    def _finish_job(self, *, job: Job, status: JobStatus) -> None:
        if self._state_machine.ensure_transition(
            job_id=job.job_id,
            from_status=job.status,
            to_status=status,
        ):
            job.status = status
        self._store.save(job)
        logger.info("SS_WORKER_JOB_DONE", extra={"job_id": job.job_id, "status": job.status.value})

    def _execute_plan(self, *, job: Job, run_id: str) -> RunResult:
        if job.llm_plan is None:
            logger.warning("SS_WORKER_PLAN_MISSING", extra={"job_id": job.job_id})
            return RunResult(
                job_id=job.job_id,
                run_id=run_id,
                ok=False,
                exit_code=None,
                timed_out=False,
                artifacts=tuple(),
                error=RunError(error_code="PLAN_MISSING", message="job missing llm_plan"),
            )

        do_file = ""
        for step in job.llm_plan.steps:
            if step.type == PlanStepType.GENERATE_STATA_DO:
                do_file = self._generate_do_file(job=job, run_id=run_id, step=step)
                continue
            if step.type == PlanStepType.RUN_STATA:
                timeout_seconds = self._timeout_seconds(step=step)
                if do_file == "":
                    do_file = self._default_do_file(job=job, run_id=run_id)
                return self._runner.run(
                    job_id=job.job_id,
                    run_id=run_id,
                    do_file=do_file,
                    timeout_seconds=timeout_seconds,
                )

        logger.warning("SS_WORKER_PLAN_NO_RUN_STEP", extra={"job_id": job.job_id})
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=False,
            exit_code=None,
            timed_out=False,
            artifacts=tuple(),
            error=RunError(error_code="PLAN_INVALID", message="plan missing RUN_STATA step"),
        )

    def _generate_do_file(self, *, job: Job, run_id: str, step: PlanStep) -> str:
        template = str(step.params.get("template", ""))
        requirement_fingerprint = str(step.params.get("requirement_fingerprint", ""))
        lines = [
            "* SS generated do-file (stub)",
            f"* template: {template}",
            f"* job_id: {job.job_id}",
            f"* run_id: {run_id}",
            f"* requirement_fingerprint: {requirement_fingerprint}",
            'display "SS stub do-file"',
            "exit 0",
        ]
        return "\n".join(lines) + "\n"

    def _default_do_file(self, *, job: Job, run_id: str) -> str:
        lines = [
            "* SS generated do-file (default)",
            f"* job_id: {job.job_id}",
            f"* run_id: {run_id}",
            'display "SS default do-file"',
            "exit 0",
        ]
        return "\n".join(lines) + "\n"

    def _timeout_seconds(self, *, step: PlanStep) -> int | None:
        raw = step.params.get("timeout_seconds")
        if raw is None:
            return None
        if isinstance(raw, (dict, list)):
            return None
        try:
            seconds = int(raw)
        except (TypeError, ValueError):
            return None
        if seconds <= 0:
            return None
        return seconds

    def _find_attempt(self, *, job: Job, run_id: str) -> RunAttempt:
        for attempt in reversed(job.runs):
            if attempt.run_id == run_id:
                return attempt
        raise ValueError("run attempt not found")

    def _index_artifacts(self, *, job: Job, result: RunResult) -> None:
        known = {(ref.kind, ref.rel_path) for ref in job.artifacts_index}
        for ref in result.artifacts:
            key = (ref.kind, ref.rel_path)
            if key in known:
                continue
            job.artifacts_index.append(ref)
            known.add(key)

    def _normalized_max_attempts(self) -> int:
        try:
            value = int(self._retry.max_attempts)
        except (TypeError, ValueError):
            return 1
        if value <= 0:
            return 1
        return value

    def _backoff_seconds(self, *, attempt: int) -> float:
        try:
            base = float(self._retry.backoff_base_seconds)
        except (TypeError, ValueError):
            base = 0.0
        try:
            cap = float(self._retry.backoff_max_seconds)
        except (TypeError, ValueError):
            cap = 0.0
        if base <= 0:
            return 0.0
        if cap <= 0:
            cap = base
        seconds = base * (2 ** max(attempt - 1, 0))
        return float(min(seconds, cap))

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
