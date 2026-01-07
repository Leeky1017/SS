from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api.deps import get_draft_service, get_tenant_id
from src.api.schemas import DraftPreviewResponse
from src.domain.draft_service import DraftService

router = APIRouter(tags=["draft"])


@router.get("/jobs/{job_id}/draft/preview", response_model=DraftPreviewResponse)
async def draft_preview(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: DraftService = Depends(get_draft_service),
) -> DraftPreviewResponse:
    draft = await svc.preview(tenant_id=tenant_id, job_id=job_id)
    return DraftPreviewResponse(job_id=job_id, draft_text=draft.text)
