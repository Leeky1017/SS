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

class PlanTemplateMetaNotFoundError(SSError):
    def __init__(self, *, job_id: str, template_id: str):
        super().__init__(
            error_code="PLAN_TEMPLATE_META_NOT_FOUND",
            message=f"plan template meta not found: {job_id} (template_id={template_id})",
            status_code=500,
        )


class PlanTemplateMetaInvalidError(SSError):
    def __init__(self, *, job_id: str, template_id: str, reason: str):
        super().__init__(
            error_code="PLAN_TEMPLATE_META_INVALID",
            message=(
                f"plan template meta invalid: {job_id} "
                f"(template_id={template_id}, reason={reason})"
            ),
            status_code=500,
        )


class PlanCompositionInvalidError(SSError):
    def __init__(
        self,
        *,
        reason: str,
        step_id: str | None = None,
        dataset_ref: str | None = None,
        product_id: str | None = None,
    ):
        ctx_parts: list[str] = []
        if step_id is not None:
            ctx_parts.append(f"step_id={step_id}")
        if dataset_ref is not None:
            ctx_parts.append(f"dataset_ref={dataset_ref}")
        if product_id is not None:
            ctx_parts.append(f"product_id={product_id}")

        ctx = ""
        if len(ctx_parts) > 0:
            ctx = " (" + ", ".join(ctx_parts) + ")"
        super().__init__(
            error_code="PLAN_COMPOSITION_INVALID",
            message=f"plan composition invalid: {reason}{ctx}",
            status_code=400,
        )


class ContractColumnNotFoundError(SSError):
    def __init__(self, *, missing: list[str]):
        missing_csv = ",".join(missing)
        super().__init__(
            error_code="CONTRACT_COLUMN_NOT_FOUND",
            message=(
                "One or more variables are not present in the primary dataset columns: "
                f"missing={missing_csv}"
            ),
            status_code=400,
        )
