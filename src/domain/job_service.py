from __future__ import annotations

import logging
from collections import Counter
from dataclasses import dataclass

from src.domain.idempotency import JobIdempotency
from src.domain.models import JOB_SCHEMA_VERSION_V1, Job, JobInputs, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobAlreadyExistsError
from src.infra.job_store import JobStore
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


class JobScheduler:
    def schedule(self, *, job: Job) -> None:
        raise NotImplementedError


@dataclass(frozen=True)
class NoopJobScheduler(JobScheduler):
    """Placeholder scheduler: records schedule intent only."""

    def schedule(self, *, job: Job) -> None:
        return None


class JobService:
    """Job lifecycle: create → confirm (queue/schedule)."""

    def __init__(
        self,
        *,
        store: JobStore,
        scheduler: JobScheduler,
        state_machine: JobStateMachine,
        idempotency: JobIdempotency,
    ):
        self._store = store
        self._scheduler = scheduler
        self._state_machine = state_machine
        self._idempotency = idempotency

    def create_job(
        self,
        *,
        requirement: str | None,
        inputs_fingerprint: str | None = None,
        plan_revision: str | int | None = None,
    ) -> Job:
        idempotency_key = self._idempotency.compute_key(
            inputs_fingerprint=inputs_fingerprint,
            requirement=requirement,
            plan_revision=plan_revision,
        )
        job_id = self._idempotency.derive_job_id(idempotency_key=idempotency_key)
        inputs = None
        if inputs_fingerprint is not None:
            inputs = JobInputs(fingerprint=inputs_fingerprint)
        job = Job(
            schema_version=JOB_SCHEMA_VERSION_V1,
            job_id=job_id,
            status=JobStatus.CREATED,
            requirement=requirement,
            created_at=utc_now().isoformat(),
            inputs=inputs,
        )
        try:
            self._store.create(job)
        except JobAlreadyExistsError:
            existing = self._store.load(job_id)
            logger.info(
                "SS_JOB_CREATE_IDEMPOTENT_HIT",
                extra={"job_id": job_id, "idempotency_key": idempotency_key},
            )
            return existing
        logger.info("SS_JOB_CREATED", extra={"job_id": job_id, "idempotency_key": idempotency_key})
        return job

    def confirm_job(self, *, job_id: str, confirmed: bool) -> Job:
        if not confirmed:
            job = self._store.load(job_id)
            logger.info(
                "SS_JOB_CONFIRM_SKIPPED",
                extra={"job_id": job_id, "status": job.status.value},
            )
            return job
        updated = self.trigger_run(job_id=job_id)
        logger.info("SS_JOB_CONFIRMED", extra={"job_id": job_id, "status": updated.status.value})
        return updated

    def trigger_run(self, *, job_id: str) -> Job:
        job = self._store.load(job_id)
        if job.status in {
            JobStatus.QUEUED,
            JobStatus.RUNNING,
            JobStatus.SUCCEEDED,
            JobStatus.FAILED,
        }:
            logger.info(
                "SS_JOB_RUN_IDEMPOTENT",
                extra={"job_id": job_id, "status": job.status.value},
            )
            return job

        if self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.CONFIRMED,
        ):
            job.status = JobStatus.CONFIRMED
        if self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.QUEUED,
        ):
            job.status = JobStatus.QUEUED
            if job.scheduled_at is None:
                job.scheduled_at = utc_now().isoformat()
            self._scheduler.schedule(job=job)
        self._store.save(job)
        logger.info("SS_JOB_RUN_QUEUED", extra={"job_id": job_id, "status": job.status.value})
        return job

    def get_job_summary(self, *, job_id: str) -> dict:
        job = self._store.load(job_id)
        draft_summary = None
        if job.draft is not None:
            draft_summary = {
                "created_at": job.draft.created_at,
                "text_chars": len(job.draft.text),
            }

        kinds = Counter(ref.kind.value for ref in job.artifacts_index)
        artifacts_summary = {"total": len(job.artifacts_index), "by_kind": dict(kinds)}

        latest_run = None
        if job.runs:
            attempt = job.runs[-1]
            latest_run = {
                "run_id": attempt.run_id,
                "attempt": attempt.attempt,
                "status": attempt.status,
                "started_at": attempt.started_at,
                "ended_at": attempt.ended_at,
                "artifacts_count": len(attempt.artifacts),
            }

        return {
            "job_id": job.job_id,
            "status": job.status.value,
            "timestamps": {"created_at": job.created_at, "scheduled_at": job.scheduled_at},
            "draft": draft_summary,
            "artifacts": artifacts_summary,
            "latest_run": latest_run,
        }
