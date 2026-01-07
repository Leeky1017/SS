from __future__ import annotations

from fastapi import APIRouter, Body, Depends
from fastapi.responses import FileResponse
from opentelemetry.trace import get_tracer

from src.api.deps import (
    get_artifacts_service,
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
    LLMPlanResponse,
    RunJobResponse,
)
from src.domain.artifacts_service import ArtifactsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.models import JobConfirmation
from src.domain.plan_service import PlanService
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
    svc: JobQueryService = Depends(get_job_query_service),
) -> GetJobResponse:
    return GetJobResponse.model_validate(svc.get_job_summary(tenant_id=tenant_id, job_id=job_id))


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
    job = svc.confirm_job(
        tenant_id=tenant_id,
        job_id=job_id,
        confirmed=payload.confirmed,
        notes=payload.notes,
    )
    return ConfirmJobResponse(
        job_id=job.job_id,
        status=job.status.value,
        scheduled_at=job.scheduled_at,
    )


@router.post("/jobs/{job_id}/plan/freeze", response_model=FreezePlanResponse)
def freeze_plan(
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
def get_plan(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: PlanService = Depends(get_plan_service),
) -> GetPlanResponse:
    plan = svc.get_frozen_plan(tenant_id=tenant_id, job_id=job_id)
    return GetPlanResponse(
        job_id=job_id,
        plan=LLMPlanResponse.model_validate(plan.model_dump(mode="json")),
    )
