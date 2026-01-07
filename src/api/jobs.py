from __future__ import annotations

from fastapi import APIRouter, Body, Depends, File, Form, Query, UploadFile
from fastapi.responses import FileResponse
from opentelemetry.trace import get_tracer

from src.api.deps import (
    get_artifacts_service,
    get_job_inputs_service,
    get_job_service,
    get_tenant_id,
)
from src.api.schemas import (
    ArtifactIndexItem,
    ArtifactsIndexResponse,
    ConfirmJobRequest,
    ConfirmJobResponse,
    CreateJobRequest,
    CreateJobResponse,
    GetJobResponse,
    InputsPreviewResponse,
    InputsUploadResponse,
    RunJobResponse,
)
from src.domain.artifacts_service import ArtifactsService
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_service import JobService
from src.infra.tracing import synthetic_parent_context_for_trace_id

router = APIRouter(tags=["jobs"])


@router.post("/jobs", response_model=CreateJobResponse)
def create_job(
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
def get_job(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> GetJobResponse:
    return GetJobResponse.model_validate(svc.get_job_summary(tenant_id=tenant_id, job_id=job_id))


@router.post("/jobs/{job_id}/inputs/upload", response_model=InputsUploadResponse)
async def upload_job_inputs(
    job_id: str,
    file: UploadFile = File(...),
    role: str = Form(default="primary_dataset"),
    filename: str | None = Form(default=None),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobInputsService = Depends(get_job_inputs_service),
) -> InputsUploadResponse:
    payload = svc.upload_primary_dataset(
        tenant_id=tenant_id,
        job_id=job_id,
        data=await file.read(),
        original_name=file.filename,
        filename_override=filename,
        content_type=file.content_type,
    )
    return InputsUploadResponse.model_validate(payload)


@router.get("/jobs/{job_id}/inputs/preview", response_model=InputsPreviewResponse)
def preview_job_inputs(
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
def get_job_artifacts(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: ArtifactsService = Depends(get_artifacts_service),
) -> ArtifactsIndexResponse:
    artifacts = svc.list_artifacts(tenant_id=tenant_id, job_id=job_id)
    items = [ArtifactIndexItem.model_validate(item) for item in artifacts]
    return ArtifactsIndexResponse(job_id=job_id, artifacts=items)


@router.get("/jobs/{job_id}/artifacts/{artifact_id:path}")
def download_job_artifact(
    job_id: str,
    artifact_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: ArtifactsService = Depends(get_artifacts_service),
) -> FileResponse:
    path = svc.resolve_download_path(tenant_id=tenant_id, job_id=job_id, rel_path=artifact_id)
    filename = artifact_id.rsplit("/", 1)[-1]
    return FileResponse(path=path, filename=filename)


@router.post("/jobs/{job_id}/run", response_model=RunJobResponse)
def run_job(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> RunJobResponse:
    job = svc.trigger_run(tenant_id=tenant_id, job_id=job_id)
    return RunJobResponse(job_id=job.job_id, status=job.status.value, scheduled_at=job.scheduled_at)


@router.post("/jobs/{job_id}/confirm", response_model=ConfirmJobResponse)
def confirm_job(
    job_id: str,
    payload: ConfirmJobRequest = Body(default_factory=ConfirmJobRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> ConfirmJobResponse:
    job = svc.confirm_job(tenant_id=tenant_id, job_id=job_id, confirmed=payload.confirmed)
    return ConfirmJobResponse(
        job_id=job.job_id,
        status=job.status.value,
        scheduled_at=job.scheduled_at,
    )
