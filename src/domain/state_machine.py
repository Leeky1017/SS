from __future__ import annotations

import logging
from dataclasses import dataclass

from src.domain.models import JobStatus
from src.infra.exceptions import SSError

logger = logging.getLogger(__name__)

_ALLOWED_TRANSITIONS: dict[JobStatus, frozenset[JobStatus]] = {
    JobStatus.CREATED: frozenset({JobStatus.DRAFT_READY}),
    JobStatus.DRAFT_READY: frozenset({JobStatus.CONFIRMED}),
    JobStatus.CONFIRMED: frozenset({JobStatus.QUEUED}),
    JobStatus.QUEUED: frozenset({JobStatus.RUNNING}),
    JobStatus.RUNNING: frozenset({JobStatus.SUCCEEDED, JobStatus.FAILED}),
    JobStatus.SUCCEEDED: frozenset(),
    JobStatus.FAILED: frozenset({JobStatus.QUEUED}),
}


class JobIllegalTransitionError(SSError):
    def __init__(self, *, job_id: str, from_status: JobStatus, to_status: JobStatus):
        message = (
            f"illegal job status transition: {job_id} {from_status.value} -> {to_status.value}"
        )
        super().__init__(
            error_code="JOB_ILLEGAL_TRANSITION",
            message=message,
            status_code=409,
        )


@dataclass(frozen=True)
class JobStateMachine:
    def can_transition(self, *, from_status: JobStatus, to_status: JobStatus) -> bool:
        if from_status == to_status:
            return True
        return to_status in _ALLOWED_TRANSITIONS.get(from_status, frozenset())

    def ensure_transition(
        self,
        *,
        job_id: str,
        from_status: JobStatus,
        to_status: JobStatus,
    ) -> bool:
        if from_status == to_status:
            return False
        if self.can_transition(from_status=from_status, to_status=to_status):
            return True
        logger.warning(
            "SS_JOB_ILLEGAL_TRANSITION",
            extra={
                "job_id": job_id,
                "from_status": from_status.value,
                "to_status": to_status.value,
            },
        )
        raise JobIllegalTransitionError(
            job_id=job_id,
            from_status=from_status,
            to_status=to_status,
        )
