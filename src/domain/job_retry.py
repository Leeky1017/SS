from __future__ import annotations

import logging

from src.domain.audit import AuditContext, AuditLogger
from src.domain.job_store import JobStore
from src.domain.job_support import JobScheduler, emit_job_audit
from src.domain.models import Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


def retry_failed_job(
    *,
    store: JobStore,
    scheduler: JobScheduler,
    state_machine: JobStateMachine,
    audit: AuditLogger,
    audit_context: AuditContext,
    tenant_id: str = DEFAULT_TENANT_ID,
    job: Job,
) -> Job:
    from_status = job.status.value
    state_machine.ensure_transition(
        job_id=job.job_id,
        from_status=job.status,
        to_status=JobStatus.QUEUED,
    )
    job.status = JobStatus.QUEUED
    job.scheduled_at = utc_now().isoformat()
    scheduler.schedule(job=job)
    store.save(tenant_id=tenant_id, job=job)
    logger.info(
        "SS_JOB_RUN_RETRY_QUEUED",
        extra={"tenant_id": tenant_id, "job_id": job.job_id, "from_status": from_status},
    )
    emit_job_audit(
        audit=audit,
        audit_context=audit_context,
        action="job.run.trigger",
        tenant_id=tenant_id,
        job_id=job.job_id,
        result="success",
        changes={
            "from_status": from_status,
            "to_status": job.status.value,
            "scheduled_at": job.scheduled_at,
        },
        metadata={"retry": True},
    )
    return job
