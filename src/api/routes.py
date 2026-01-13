from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api import (
    draft,
    health,
    inputs_bundle,
    inputs_primary_sheet,
    inputs_upload_sessions,
    jobs,
    metrics,
    task_codes,
)
from src.api.admin.routes import router as admin_router
from src.api.v1_auth import enforce_v1_job_bearer_auth

ops_router = APIRouter()
ops_router.include_router(health.router)
ops_router.include_router(metrics.router)

api_v1_router = APIRouter(prefix="/v1")
api_v1_router.include_router(
    jobs.router,
    dependencies=[Depends(enforce_v1_job_bearer_auth)],
)
api_v1_router.include_router(draft.router, dependencies=[Depends(enforce_v1_job_bearer_auth)])
api_v1_router.include_router(
    inputs_bundle.router,
    dependencies=[Depends(enforce_v1_job_bearer_auth)],
)
api_v1_router.include_router(
    inputs_primary_sheet.router,
    dependencies=[Depends(enforce_v1_job_bearer_auth)],
)
api_v1_router.include_router(
    inputs_upload_sessions.router,
    dependencies=[Depends(enforce_v1_job_bearer_auth)],
)
api_v1_router.include_router(task_codes.router)

admin_api_router = admin_router
