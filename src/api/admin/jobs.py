from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from fastapi.responses import FileResponse, Response

from src.api.admin.deps import get_job_indexer
from src.api.admin.schemas import (
    AdminArtifactItem,
    AdminJobDetailResponse,
    AdminJobListItem,
    AdminJobListResponse,
    AdminJobRetryResponse,
    AdminRunAttemptItem,
)
from src.api.deps import (
    get_artifacts_service,
    get_job_service,
    get_job_store,
    get_tenant_id,
)
from src.domain.artifacts_service import ArtifactsService
from src.domain.job_indexer import JobIndexer
from src.domain.job_service import JobService
from src.domain.job_store import JobStore
from src.utils.json_types import JsonObject

router = APIRouter(prefix="/jobs", tags=["admin-jobs"])


@router.get("", response_model=AdminJobListResponse)
async def list_jobs(
    status: str | None = Query(default=None),
    tenant_id: str | None = Query(default=None),
    indexer: JobIndexer = Depends(get_job_indexer),
) -> AdminJobListResponse:
    items = indexer.list_jobs(tenant_id=tenant_id)
    jobs = [
        AdminJobListItem(
            tenant_id=item.tenant_id,
            job_id=item.job_id,
            status=item.status,
            created_at=item.created_at,
            updated_at=item.updated_at,
        )
        for item in items
        if status is None or item.status == status
    ]
    return AdminJobListResponse(jobs=jobs)


@router.get("/{job_id}", response_model=AdminJobDetailResponse)
async def get_job_detail(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    store: JobStore = Depends(get_job_store),
    artifacts: ArtifactsService = Depends(get_artifacts_service),
) -> AdminJobDetailResponse:
    job = store.load(tenant_id=tenant_id, job_id=job_id)
    artifact_items = [
        _to_admin_artifact_item(item)
        for item in artifacts.list_artifacts(tenant_id=tenant_id, job_id=job_id)
    ]
    runs = [
        AdminRunAttemptItem(
            run_id=run.run_id,
            attempt=run.attempt,
            status=run.status,
            started_at=run.started_at,
            ended_at=run.ended_at,
            artifacts_count=len(run.artifacts),
        )
        for run in job.runs
    ]
    draft_text = None if job.draft is None else job.draft.text
    draft_created_at = None if job.draft is None else job.draft.created_at
    return AdminJobDetailResponse(
        tenant_id=tenant_id,
        job_id=job.job_id,
        status=job.status.value,
        created_at=job.created_at,
        scheduled_at=job.scheduled_at,
        requirement=job.requirement,
        draft_text=draft_text,
        draft_created_at=draft_created_at,
        redeem_task_code=job.redeem_task_code,
        auth_token=job.auth_token,
        auth_expires_at=job.auth_expires_at,
        runs=runs,
        artifacts=artifact_items,
    )


@router.post("/{job_id}/retry", response_model=AdminJobRetryResponse)
async def retry_job(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: JobService = Depends(get_job_service),
) -> AdminJobRetryResponse:
    job = svc.trigger_run(tenant_id=tenant_id, job_id=job_id)
    return AdminJobRetryResponse(
        tenant_id=tenant_id,
        job_id=job.job_id,
        status=job.status.value,
        scheduled_at=job.scheduled_at,
    )


@router.get("/{job_id}/artifacts", response_model=list[AdminArtifactItem])
async def list_job_artifacts(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    artifacts: ArtifactsService = Depends(get_artifacts_service),
) -> list[AdminArtifactItem]:
    return [
        _to_admin_artifact_item(item)
        for item in artifacts.list_artifacts(tenant_id=tenant_id, job_id=job_id)
    ]


@router.get("/{job_id}/artifacts/{artifact_id:path}")
async def download_job_artifact(
    job_id: str,
    artifact_id: str,
    tenant_id: str = Depends(get_tenant_id),
    artifacts: ArtifactsService = Depends(get_artifacts_service),
) -> Response:
    path = artifacts.resolve_download_path(tenant_id=tenant_id, job_id=job_id, rel_path=artifact_id)
    filename = artifact_id.rsplit("/", 1)[-1]
    return FileResponse(
        path=str(path),
        media_type="application/octet-stream",
        filename=filename,
    )


def _to_admin_artifact_item(item: JsonObject) -> AdminArtifactItem:
    kind_value = item.get("kind")
    rel_path_value = item.get("rel_path")
    created_at_value = item.get("created_at")
    kind = kind_value if isinstance(kind_value, str) else ""
    rel_path = rel_path_value if isinstance(rel_path_value, str) else ""
    created_at = created_at_value if isinstance(created_at_value, str) else None

    meta: dict[str, str | int | float | bool | None] = {}
    meta_value = item.get("meta")
    if isinstance(meta_value, dict):
        for key, value in meta_value.items():
            if not isinstance(key, str):
                continue
            if isinstance(value, (str, int, float, bool)) or value is None:
                meta[key] = value
    return AdminArtifactItem(kind=kind, rel_path=rel_path, created_at=created_at, meta=meta)
