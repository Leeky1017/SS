from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api import draft, health, inputs_bundle, jobs, metrics, task_codes
from src.api.v1_auth import enforce_v1_job_bearer_auth, enforce_v1_legacy_post_jobs_enabled

api_router = APIRouter()
api_router.include_router(jobs.router)
api_router.include_router(draft.router)
api_router.include_router(health.router)
api_router.include_router(metrics.router)

api_v1_router = APIRouter(prefix="/v1")
api_v1_router.include_router(
    jobs.router,
    dependencies=[
        Depends(enforce_v1_legacy_post_jobs_enabled),
        Depends(enforce_v1_job_bearer_auth),
    ],
)
api_v1_router.include_router(draft.router, dependencies=[Depends(enforce_v1_job_bearer_auth)])
api_v1_router.include_router(
    inputs_bundle.router,
    dependencies=[Depends(enforce_v1_job_bearer_auth)],
)
api_v1_router.include_router(task_codes.router)
