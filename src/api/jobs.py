from __future__ import annotations

from collections.abc import Sequence

from fastapi import APIRouter, Body, Depends, File, Form, Query, UploadFile
from fastapi.responses import Response
from opentelemetry.trace import get_tracer

from src.api.deps import (
    get_artifacts_service,
    get_job_inputs_service,
    get_job_query_service,
    get_job_service,
    get_plan_service,
    get_tenant_id,
)
from src.api.schemas import (
    ArtifactIndexItem,
    ArtifactsIndexResponse,
    ConfirmJobRequest,
    ConfirmJobResponse,
    CreateJobRequest,
    CreateJobResponse,
    FreezePlanRequest,
    FreezePlanResponse,
    GetJobResponse,
    GetPlanResponse,
    InputsPreviewResponse,
    InputsUploadResponse,
    LLMPlanResponse,
    RunJobResponse,
)
from src.domain.artifacts_service import ArtifactsService
from src.domain.inputs_manifest import ROLE_PRIMARY_DATASET, ROLE_SECONDARY_DATASET
from src.domain.job_inputs_service import DatasetUpload, JobInputsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.models import JobConfirmation
from src.domain.plan_service import PlanService
from src.infra.input_exceptions import InputFilenameCountMismatchError, InputRoleCountMismatchError
from src.infra.tracing import synthetic_parent_context_for_trace_id

router = APIRouter(tags=["jobs"])


@router.post("/jobs", response_model=CreateJobResponse)
async def create_job(
    payload: CreateJobRequest = Body(default_factory=CreateJobRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> CreateJobResponse:
    job = svc.create_job(tenant_id=tenant_id, requirement=payload.requirement)
    if job.trace_id is not None:
        context = synthetic_parent_context_for_trace_id(trace_id=job.trace_id, sampled=True)
        tracer = get_tracer(__name__)
        with tracer.start_as_current_span("ss.job.create", context=context) as span:
            span.set_attribute("ss.job_id", job.job_id)
    return CreateJobResponse(job_id=job.job_id, trace_id=job.trace_id, status=job.status.value)


@router.get("/jobs/{job_id}", response_model=GetJobResponse)
async def get_job(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: JobQueryService = Depends(get_job_query_service),
) -> GetJobResponse:
    return GetJobResponse.model_validate(svc.get_job_summary(tenant_id=tenant_id, job_id=job_id))


@router.post("/jobs/{job_id}/inputs/upload", response_model=InputsUploadResponse)
async def upload_job_inputs(
    job_id: str,
    file: list[UploadFile] = File(...),
    role: list[str] | None = Form(default=None),
    filename: list[str] | None = Form(default=None),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobInputsService = Depends(get_job_inputs_service),
) -> InputsUploadResponse:
    file_count = len(file)
    roles: Sequence[str]
    if role is None:
        roles = [ROLE_PRIMARY_DATASET] + [ROLE_SECONDARY_DATASET] * (file_count - 1)
    else:
        roles = role
    if len(roles) != file_count:
        raise InputRoleCountMismatchError(expected=file_count, actual=len(roles))

    filename_overrides: Sequence[str | None]
    if filename is None:
        filename_overrides = [None for _ in range(file_count)]
    else:
        if len(filename) != file_count:
            raise InputFilenameCountMismatchError(expected=file_count, actual=len(filename))
        filename_overrides = filename

    uploads = [
        DatasetUpload(
            role=roles[index],
            data=await item.read(),
            original_name=item.filename,
            filename_override=filename_overrides[index],
            content_type=item.content_type,
        )
        for index, item in enumerate(file)
    ]
    payload = svc.upload_datasets(tenant_id=tenant_id, job_id=job_id, uploads=uploads)
    return InputsUploadResponse.model_validate(payload)


@router.get("/jobs/{job_id}/inputs/preview", response_model=InputsPreviewResponse)
async def preview_job_inputs(
    job_id: str,
    rows: int = Query(default=20, ge=1, le=200),
    columns: int = Query(default=50, ge=1, le=200),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobInputsService = Depends(get_job_inputs_service),
) -> InputsPreviewResponse:
    payload = svc.preview_primary_dataset(
        tenant_id=tenant_id,
        job_id=job_id,
        rows=rows,
        columns=columns,
    )
    return InputsPreviewResponse.model_validate(payload)


@router.get("/jobs/{job_id}/artifacts", response_model=ArtifactsIndexResponse)
async def get_job_artifacts(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: ArtifactsService = Depends(get_artifacts_service),
) -> ArtifactsIndexResponse:
    artifacts = svc.list_artifacts(tenant_id=tenant_id, job_id=job_id)
    items = [ArtifactIndexItem.model_validate(item) for item in artifacts]
    return ArtifactsIndexResponse(job_id=job_id, artifacts=items)


@router.get("/jobs/{job_id}/artifacts/{artifact_id:path}")
async def download_job_artifact(
    job_id: str,
    artifact_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: ArtifactsService = Depends(get_artifacts_service),
) -> Response:
    path = svc.resolve_download_path(tenant_id=tenant_id, job_id=job_id, rel_path=artifact_id)
    filename = artifact_id.rsplit("/", 1)[-1]
    return Response(
        content=path.read_bytes(),
        media_type="application/octet-stream",
        headers={"Content-Disposition": f'attachment; filename=\"{filename}\"'},
    )


@router.post("/jobs/{job_id}/run", response_model=RunJobResponse)
async def run_job(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> RunJobResponse:
    job = svc.trigger_run(tenant_id=tenant_id, job_id=job_id)
    return RunJobResponse(job_id=job.job_id, status=job.status.value, scheduled_at=job.scheduled_at)


@router.post("/jobs/{job_id}/confirm", response_model=ConfirmJobResponse)
async def confirm_job(
    job_id: str,
    payload: ConfirmJobRequest = Body(default_factory=ConfirmJobRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> ConfirmJobResponse:
    job = svc.confirm_job(
        tenant_id=tenant_id,
        job_id=job_id,
        confirmed=payload.confirmed,
        notes=payload.notes,
        variable_corrections=payload.variable_corrections,
        default_overrides=payload.default_overrides,
    )
    return ConfirmJobResponse(
        job_id=job.job_id,
        status=job.status.value,
        scheduled_at=job.scheduled_at,
    )


@router.post("/jobs/{job_id}/plan/freeze", response_model=FreezePlanResponse)
async def freeze_plan(
    job_id: str,
    payload: FreezePlanRequest = Body(default_factory=FreezePlanRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: PlanService = Depends(get_plan_service),
) -> FreezePlanResponse:
    plan = svc.freeze_plan(
        tenant_id=tenant_id,
        job_id=job_id,
        confirmation=JobConfirmation(notes=payload.notes),
    )
    return FreezePlanResponse(
        job_id=job_id,
        plan=LLMPlanResponse.model_validate(plan.model_dump(mode="json")),
    )


@router.get("/jobs/{job_id}/plan", response_model=GetPlanResponse)
async def get_plan(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: PlanService = Depends(get_plan_service),
) -> GetPlanResponse:
    plan = svc.get_frozen_plan(tenant_id=tenant_id, job_id=job_id)
    return GetPlanResponse(
        job_id=job_id,
        plan=LLMPlanResponse.model_validate(plan.model_dump(mode="json")),
    )
