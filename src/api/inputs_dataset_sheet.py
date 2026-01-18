from __future__ import annotations

from fastapi import APIRouter, Depends, Query

from src.api.deps import (
    get_job_inputs_service,
    get_job_store,
    get_job_workspace_store,
    get_tenant_id,
)
from src.api.inputs_preview_schemas import InputsPreviewResponse
from src.domain.inputs_sheet_selection_service import InputsSheetSelectionService
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore

router = APIRouter(tags=["inputs"])


@router.post(
    "/jobs/{job_id}/inputs/datasets/{dataset_key}/sheet",
    response_model=InputsPreviewResponse,
)
async def select_dataset_excel_sheet(
    job_id: str,
    dataset_key: str,
    sheet_name: str = Query(..., min_length=1),
    rows: int = Query(default=20, ge=1, le=200),
    columns: int = Query(default=50, ge=1, le=200),
    tenant_id: str = Depends(get_tenant_id),
    store: JobStore = Depends(get_job_store),
    workspace: JobWorkspaceStore = Depends(get_job_workspace_store),
    inputs_svc: JobInputsService = Depends(get_job_inputs_service),
) -> InputsPreviewResponse:
    InputsSheetSelectionService(store=store, workspace=workspace).select_dataset_excel_sheet(
        tenant_id=tenant_id,
        job_id=job_id,
        dataset_key=dataset_key,
        sheet_name=sheet_name,
    )
    payload = inputs_svc.preview_primary_dataset(
        tenant_id=tenant_id,
        job_id=job_id,
        rows=rows,
        columns=columns,
    )
    return InputsPreviewResponse.model_validate(payload)
