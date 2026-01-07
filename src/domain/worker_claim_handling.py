from __future__ import annotations

import logging
from collections.abc import Callable

from src.domain.job_store import JobStore
from src.domain.models import Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.domain.worker_queue import QueueClaim
from src.infra.exceptions import JobDataCorruptedError, JobNotFoundError, JobStoreIOError

logger = logging.getLogger(__name__)

Ack = Callable[[QueueClaim], None]
Release = Callable[[QueueClaim], None]
EmitAudit = Callable[..., None]


def load_job_or_handle(
    *,
    store: JobStore,
    claim: QueueClaim,
    ack: Ack,
    release: Release,
) -> Job | None:
    try:
        return store.load(tenant_id=claim.tenant_id, job_id=claim.job_id)
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
        ack(claim)
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
        ack(claim)
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
        release(claim)
        return None


def ensure_job_claimable(
    *,
    store: JobStore,
    state_machine: JobStateMachine,
    job: Job,
    claim: QueueClaim,
    ack: Ack,
    release: Release,
    emit_audit: EmitAudit,
) -> bool:
    if job.status == JobStatus.QUEUED:
        if state_machine.ensure_transition(
            job_id=job.job_id,
            from_status=job.status,
            to_status=JobStatus.RUNNING,
        ):
            from_status = job.status.value
            job.status = JobStatus.RUNNING
            store.save(tenant_id=claim.tenant_id, job=job)
            emit_audit(
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
            extra={"job_id": job.job_id, "status": job.status.value, "claim_id": claim.claim_id},
        )
        ack(claim)
        return False

    logger.warning(
        "SS_WORKER_JOB_NOT_READY",
        extra={"job_id": job.job_id, "status": job.status.value, "claim_id": claim.claim_id},
    )
    release(claim)
    return False
