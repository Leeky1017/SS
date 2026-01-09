from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api.deps import get_draft_service, get_tenant_id
from src.api.schemas import DraftPreviewDataSource, DraftPreviewResponse, InputsPreviewColumn
from src.domain.draft_service import DraftService

router = APIRouter(tags=["draft"])


@router.get("/jobs/{job_id}/draft/preview", response_model=DraftPreviewResponse)
async def draft_preview(
    job_id: str,
    tenant_id: str = Depends(get_tenant_id),
    svc: DraftService = Depends(get_draft_service),
) -> DraftPreviewResponse:
    draft = await svc.preview(tenant_id=tenant_id, job_id=job_id)
    return DraftPreviewResponse(
        job_id=job_id,
        draft_text=draft.text,
        outcome_var=draft.outcome_var,
        treatment_var=draft.treatment_var,
        controls=list(draft.controls),
        column_candidates=list(draft.column_candidates),
        variable_types=[
            InputsPreviewColumn(name=item.name, inferred_type=item.inferred_type)
            for item in draft.variable_types
        ],
        data_sources=[
            DraftPreviewDataSource(
                dataset_key=item.dataset_key,
                role=item.role,
                original_name=item.original_name,
                format=item.format,
            )
            for item in draft.data_sources
        ],
        default_overrides=dict(draft.default_overrides),
    )
