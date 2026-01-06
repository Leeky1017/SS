from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass

from src.domain.models import JOB_SCHEMA_VERSION_V1, Job, JobStatus
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

    def __init__(self, *, store: JobStore, scheduler: JobScheduler):
        self._store = store
        self._scheduler = scheduler

    def create_job(self, *, requirement: str | None) -> Job:
        job_id = f"job_{uuid.uuid4().hex[:16]}"
        job = Job(
            schema_version=JOB_SCHEMA_VERSION_V1,
            job_id=job_id,
            status=JobStatus.CREATED.value,
            requirement=requirement,
            created_at=utc_now().isoformat(),
        )
        self._store.create(job)
        logger.info("SS_JOB_CREATED", extra={"job_id": job_id})
        return job

    def confirm_job(self, *, job_id: str, confirmed: bool) -> Job:
        job = self._store.load(job_id)
        if confirmed:
            job.status = JobStatus.QUEUED.value
            job.scheduled_at = utc_now().isoformat()
            self._scheduler.schedule(job=job)
        self._store.save(job)
        logger.info(
            "SS_JOB_CONFIRMED",
            extra={"job_id": job_id, "confirmed": bool(confirmed), "status": job.status},
        )
        return job
