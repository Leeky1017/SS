from __future__ import annotations

from src.infra.exceptions import SSError


class PlanMissingError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="PLAN_MISSING",
            message=f"plan missing: {job_id}",
            status_code=409,
        )


class PlanFreezeNotAllowedError(SSError):
    def __init__(self, *, job_id: str, status: str):
        super().__init__(
            error_code="PLAN_FREEZE_NOT_ALLOWED",
            message=f"plan freeze not allowed: {job_id} (status={status})",
            status_code=409,
        )


class PlanAlreadyFrozenError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="PLAN_ALREADY_FROZEN_CONFLICT",
            message=f"plan already frozen: {job_id}",
            status_code=409,
        )


class PlanArtifactsWriteError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="PLAN_ARTIFACTS_WRITE_FAILED",
            message=f"plan artifacts write failed: {job_id}",
            status_code=500,
        )

