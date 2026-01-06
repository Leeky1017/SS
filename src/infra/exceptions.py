from __future__ import annotations

from dataclasses import dataclass


@dataclass
class SSError(Exception):
    error_code: str
    message: str
    status_code: int = 400

    def to_dict(self) -> dict[str, str]:
        return {"error_code": self.error_code, "message": self.message}


class JobNotFoundError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_NOT_FOUND",
            message=f"job not found: {job_id}",
            status_code=404,
        )


class JobAlreadyExistsError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_ALREADY_EXISTS",
            message=f"job already exists: {job_id}",
            status_code=409,
        )


class JobDataCorruptedError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_DATA_CORRUPTED",
            message=f"job data corrupted: {job_id}",
            status_code=500,
        )


class JobStoreIOError(SSError):
    def __init__(self, *, operation: str, job_id: str):
        super().__init__(
            error_code="JOB_STORE_IO_ERROR",
            message=f"job store io error ({operation}): {job_id}",
            status_code=500,
        )


class LLMCallFailedError(SSError):
    def __init__(self, *, job_id: str, llm_call_id: str):
        super().__init__(
            error_code="LLM_CALL_FAILED",
            message=f"llm call failed: {job_id}:{llm_call_id}",
            status_code=502,
        )


class LLMArtifactsWriteError(SSError):
    def __init__(self, *, job_id: str, llm_call_id: str):
        super().__init__(
            error_code="LLM_ARTIFACTS_WRITE_FAILED",
            message=f"llm artifacts write failed: {job_id}:{llm_call_id}",
            status_code=500,
        )


class ArtifactNotFoundError(SSError):
    def __init__(self, *, job_id: str, rel_path: str):
        super().__init__(
            error_code="ARTIFACT_NOT_FOUND",
            message=f"artifact not found: {job_id}:{rel_path}",
            status_code=404,
        )


class ArtifactPathUnsafeError(SSError):
    def __init__(self, *, job_id: str, rel_path: str):
        super().__init__(
            error_code="ARTIFACT_PATH_UNSAFE",
            message=f"artifact path unsafe: {job_id}:{rel_path}",
            status_code=400,
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
            error_code="PLAN_ALREADY_FROZEN",
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


class QueueIOError(SSError):
    def __init__(self, *, operation: str, path: str):
        super().__init__(
            error_code="QUEUE_IO_ERROR",
            message=f"queue io error ({operation}): {path}",
            status_code=500,
        )


class QueueDataCorruptedError(SSError):
    def __init__(self, *, path: str):
        super().__init__(
            error_code="QUEUE_DATA_CORRUPTED",
            message=f"queue data corrupted: {path}",
            status_code=500,
        )

