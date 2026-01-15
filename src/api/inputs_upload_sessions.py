from __future__ import annotations

from fastapi import APIRouter, Body, Depends

from src.api.deps import get_tenant_id, get_upload_sessions_service
from src.api.schemas import (
    CreateUploadSessionRequest,
    FinalizeUploadFailure,
    FinalizeUploadRequest,
    FinalizeUploadResponse,
    FinalizeUploadSuccess,
    RefreshUploadUrlsRequest,
    RefreshUploadUrlsResponse,
    UploadSessionResponse,
)
from src.api.v1_auth import enforce_v1_upload_session_bearer_auth
from src.domain.upload_sessions_service import UploadSessionsService

router = APIRouter(tags=["inputs"])


@router.post(
    "/jobs/{job_id}/inputs/upload-sessions",
    response_model=UploadSessionResponse,
    openapi_extra={"x-internal": True},
)
async def create_upload_session(
    job_id: str,
    payload: CreateUploadSessionRequest = Body(...),
    tenant_id: str = Depends(get_tenant_id),
    svc: UploadSessionsService = Depends(get_upload_sessions_service),
) -> UploadSessionResponse:
    result = svc.create_upload_session(
        tenant_id=tenant_id,
        job_id=job_id,
        bundle_id=payload.bundle_id,
        file_id=payload.file_id,
    )
    return UploadSessionResponse.model_validate(result)


@router.post(
    "/upload-sessions/{upload_session_id}/refresh-urls",
    response_model=RefreshUploadUrlsResponse,
    dependencies=[Depends(enforce_v1_upload_session_bearer_auth)],
    openapi_extra={"x-internal": True},
)
async def refresh_upload_urls(
    upload_session_id: str,
    payload: RefreshUploadUrlsRequest = Body(default_factory=RefreshUploadUrlsRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: UploadSessionsService = Depends(get_upload_sessions_service),
) -> RefreshUploadUrlsResponse:
    result = svc.refresh_multipart_urls(
        tenant_id=tenant_id,
        upload_session_id=upload_session_id,
        part_numbers=payload.part_numbers,
    )
    return RefreshUploadUrlsResponse.model_validate(result)


@router.post(
    "/upload-sessions/{upload_session_id}/finalize",
    response_model=FinalizeUploadResponse,
    dependencies=[Depends(enforce_v1_upload_session_bearer_auth)],
    openapi_extra={"x-internal": True},
)
async def finalize_upload_session(
    upload_session_id: str,
    payload: FinalizeUploadRequest = Body(...),
    tenant_id: str = Depends(get_tenant_id),
    svc: UploadSessionsService = Depends(get_upload_sessions_service),
) -> FinalizeUploadResponse:
    result = svc.finalize(
        tenant_id=tenant_id,
        upload_session_id=upload_session_id,
        parts=[item.model_dump(mode="json") for item in payload.parts],
    )
    if result.get("success") is True:
        return FinalizeUploadSuccess.model_validate(result)
    return FinalizeUploadFailure.model_validate(result)
