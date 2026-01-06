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


class DoTemplateIndexNotFoundError(SSError):
    def __init__(self, *, path: str):
        super().__init__(
            error_code="DO_TEMPLATE_INDEX_NOT_FOUND",
            message=f"do template index not found: {path}",
            status_code=500,
        )


class DoTemplateIndexCorruptedError(SSError):
    def __init__(self, *, reason: str, template_id: str | None = None):
        suffix = ""
        if template_id is not None and template_id != "":
            suffix = f" (template_id={template_id})"
        super().__init__(
            error_code="DO_TEMPLATE_INDEX_CORRUPTED",
            message=f"do template index corrupted: {reason}{suffix}",
            status_code=500,
        )


class DoTemplateNotFoundError(SSError):
    def __init__(self, *, template_id: str):
        super().__init__(
            error_code="DO_TEMPLATE_NOT_FOUND",
            message=f"do template not found: {template_id}",
            status_code=404,
        )


class DoTemplateSourceNotFoundError(SSError):
    def __init__(self, *, template_id: str, path: str):
        super().__init__(
            error_code="DO_TEMPLATE_SOURCE_NOT_FOUND",
            message=f"do template source not found: {template_id} ({path})",
            status_code=404,
        )


class DoTemplateMetaNotFoundError(SSError):
    def __init__(self, *, template_id: str, path: str):
        super().__init__(
            error_code="DO_TEMPLATE_META_NOT_FOUND",
            message=f"do template meta not found: {template_id} ({path})",
            status_code=404,
        )


class DoTemplateContractInvalidError(SSError):
    def __init__(self, *, template_id: str, reason: str):
        super().__init__(
            error_code="DO_TEMPLATE_CONTRACT_INVALID",
            message=f"do template contract invalid: {template_id} ({reason})",
            status_code=500,
        )


class DoTemplateParameterMissingError(SSError):
    def __init__(self, *, template_id: str, name: str):
        super().__init__(
            error_code="DO_TEMPLATE_PARAM_MISSING",
            message=f"do template parameter missing: {template_id}:{name}",
            status_code=400,
        )


class DoTemplateParameterInvalidError(SSError):
    def __init__(self, *, template_id: str, name: str):
        super().__init__(
            error_code="DO_TEMPLATE_PARAM_INVALID",
            message=f"do template parameter invalid: {template_id}:{name}",
            status_code=400,
        )


class DoTemplateArtifactsWriteError(SSError):
    def __init__(self, *, template_id: str, job_id: str, run_id: str, rel_path: str):
        message = (
            f"do template artifacts write failed: {template_id} "
            f"({job_id}:{run_id}:{rel_path})"
        )
        super().__init__(
            error_code="DO_TEMPLATE_ARTIFACTS_WRITE_FAILED",
            message=message,
            status_code=500,
        )


class StataCmdNotFoundError(SSError):
    def __init__(self):
        super().__init__(
            error_code="STATA_CMD_NOT_FOUND",
            message=(
                "stata executable not found "
                "(set SS_STATA_CMD or install Stata in default paths)"
            ),
            status_code=500,
        )
