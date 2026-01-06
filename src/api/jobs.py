from __future__ import annotations

from fastapi import APIRouter, Body, Depends

from src.api.deps import get_job_service
from src.api.schemas import (
    ConfirmJobRequest,
    ConfirmJobResponse,
    CreateJobRequest,
    CreateJobResponse,
    GetJobResponse,
)
from src.domain.job_service import JobService

router = APIRouter(tags=["jobs"])


@router.post("/jobs", response_model=CreateJobResponse)
def create_job(
    payload: CreateJobRequest = Body(default_factory=CreateJobRequest),
    svc: JobService = Depends(get_job_service),
) -> CreateJobResponse:
    job = svc.create_job(requirement=payload.requirement)
    return CreateJobResponse(job_id=job.job_id, status=job.status.value)


@router.get("/jobs/{job_id}", response_model=GetJobResponse)
def get_job(
    job_id: str,
    svc: JobService = Depends(get_job_service),
) -> GetJobResponse:
    return GetJobResponse.model_validate(svc.get_job_summary(job_id=job_id))


@router.post("/jobs/{job_id}/confirm", response_model=ConfirmJobResponse)
def confirm_job(
    job_id: str,
    payload: ConfirmJobRequest = Body(default_factory=ConfirmJobRequest),
    svc: JobService = Depends(get_job_service),
) -> ConfirmJobResponse:
    job = svc.confirm_job(job_id=job_id, confirmed=payload.confirmed)
    return ConfirmJobResponse(
        job_id=job.job_id,
        status=job.status.value,
        scheduled_at=job.scheduled_at,
    )
