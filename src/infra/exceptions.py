from __future__ import annotations

from dataclasses import dataclass


@dataclass
class SSError(Exception):
    error_code: str
    message: str
    status_code: int = 400

    def to_dict(self) -> dict[str, str]:
        return {"error_code": self.error_code, "message": self.message}


class ServiceShuttingDownError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="SERVICE_SHUTTING_DOWN",
            message="service is shutting down",
            status_code=503,
        )


class OutOfMemoryError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="RESOURCE_OOM",
            message="system is out of memory",
            status_code=503,
        )


class JobNotFoundError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_NOT_FOUND",
            message=f"job not found: {job_id}",
            status_code=404,
        )


class JobIdUnsafeError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_ID_UNSAFE",
            message=f"job id unsafe: {job_id}",
            status_code=400,
        )


class TenantIdUnsafeError(SSError):
    def __init__(self, *, tenant_id: str):
        super().__init__(
            error_code="TENANT_ID_UNSAFE",
            message=f"tenant id unsafe: {tenant_id}",
            status_code=400,
        )


class JobAlreadyExistsError(SSError):
    def __init__(self, *, job_id: str):
        super().__init__(
            error_code="JOB_ALREADY_EXISTS",
            message=f"job already exists: {job_id}",
            status_code=409,
        )


class JobVersionConflictError(SSError):
    def __init__(self, *, job_id: str, expected_version: int, actual_version: int):
        super().__init__(
            error_code="JOB_VERSION_CONFLICT",
            message=(
                f"job version conflict: {job_id} "
                f"(expected_version={expected_version}, actual_version={actual_version})"
            ),
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


class JobStoreBackendUnsupportedError(SSError):
    def __init__(self, *, backend: str):
        super().__init__(
            error_code="JOB_STORE_BACKEND_UNSUPPORTED",
            message=f"job store backend unsupported: {backend}",
            status_code=500,
        )


class LLMCallFailedError(SSError):
    def __init__(self, *, job_id: str, llm_call_id: str):
        super().__init__(
            error_code="LLM_CALL_FAILED",
            message=f"llm call failed: {job_id}:{llm_call_id}",
            status_code=502,
        )


class LLMConfigurationError(SSError):
    def __init__(self, *, message: str):
        super().__init__(
            error_code="LLM_CONFIG_INVALID",
            message=message,
            status_code=500,
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


class OutputFormatsInvalidError(SSError):
    def __init__(self, *, reason: str, supported: tuple[str, ...]):
        supported_csv = ",".join(supported)
        super().__init__(
            error_code="OUTPUT_FORMATS_INVALID",
            message=f"output_formats invalid: {reason} (supported={supported_csv})",
            status_code=400,
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


class DoFilePlanInvalidError(SSError):
    def __init__(self, *, reason: str):
        super().__init__(
            error_code="DOFILE_PLAN_INVALID",
            message=f"dofile plan invalid: {reason}",
            status_code=400,
        )


class DoFileTemplateUnsupportedError(SSError):
    def __init__(self, *, template: str):
        super().__init__(
            error_code="DOFILE_TEMPLATE_UNSUPPORTED",
            message=f"dofile template unsupported: {template}",
            status_code=400,
        )


class DoFileInputsManifestInvalidError(SSError):
    def __init__(self, *, reason: str):
        super().__init__(
            error_code="DOFILE_INPUTS_MANIFEST_INVALID",
            message=f"dofile inputs manifest invalid: {reason}",
            status_code=400,
        )


class StataCmdNotFoundError(SSError):
    def __init__(self) -> None:
        super().__init__(
            error_code="STATA_CMD_NOT_FOUND",
            message=(
                "stata executable not found "
                "(set SS_STATA_CMD or install Stata in default paths)"
            ),
            status_code=500,
        )


from src.infra.plan_exceptions import (  # noqa: E402,F401
    PlanAlreadyFrozenError,
    PlanArtifactsWriteError,
    PlanFreezeNotAllowedError,
    PlanMissingError,
    PlanTemplateMetaInvalidError,
    PlanTemplateMetaNotFoundError,
)
