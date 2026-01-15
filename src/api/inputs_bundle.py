from __future__ import annotations

from fastapi import APIRouter, Body, Depends

from src.api.deps import get_tenant_id, get_upload_bundle_service
from src.api.schemas import BundleResponse, CreateBundleRequest
from src.domain.upload_bundle_service import Bundle, BundleFileDeclaration, UploadBundleService

router = APIRouter(tags=["inputs"])

def _bundle_payload(bundle: Bundle) -> dict[str, object]:
    payload_files: list[dict[str, object]] = []
    for item in bundle.files:
        payload_files.append(
            {
                "file_id": item.file_id,
                "filename": item.filename,
                "size_bytes": item.size_bytes,
                "role": item.role,
                "mime_type": item.mime_type,
            }
        )
    return {
        "bundle_id": bundle.bundle_id,
        "job_id": bundle.job_id,
        "files": payload_files,
    }


@router.post(
    "/jobs/{job_id}/inputs/bundle",
    response_model=BundleResponse,
    openapi_extra={"x-internal": True},
)
async def create_bundle(
    job_id: str,
    payload: CreateBundleRequest = Body(...),
    tenant_id: str = Depends(get_tenant_id),
    svc: UploadBundleService = Depends(get_upload_bundle_service),
) -> BundleResponse:
    bundle = svc.create_bundle(
        tenant_id=tenant_id,
        job_id=job_id,
        files=[
            BundleFileDeclaration(
                filename=item.filename,
                size_bytes=item.size_bytes,
                role=item.role,
                mime_type=item.mime_type,
            )
            for item in payload.files
        ],
    )
    return BundleResponse.model_validate(_bundle_payload(bundle))


@router.get(
    "/jobs/{job_id}/inputs/bundle",
    response_model=BundleResponse,
    openapi_extra={"x-internal": True},
)
async def get_bundle(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: UploadBundleService = Depends(get_upload_bundle_service),
) -> BundleResponse:
    bundle = svc.get_bundle(tenant_id=tenant_id, job_id=job_id)
    return BundleResponse.model_validate(_bundle_payload(bundle))
