from __future__ import annotations

from typing import Literal, cast

from fastapi import APIRouter, Body, Depends, Query, Response

from src.api.column_normalization_schemas import DraftColumnNameNormalization
from src.api.deps import get_draft_service, get_tenant_id
from src.api.draft_column_candidate_schemas import DraftColumnCandidateV2
from src.api.inputs_preview_schemas import InputsPreviewColumn
from src.api.required_variable_schemas import DraftRequiredVariable
from src.api.schemas import (
    DraftDataQualityWarning,
    DraftOpenUnknown,
    DraftPatchRequest,
    DraftPatchResponse,
    DraftPreviewDataSource,
    DraftPreviewPendingResponse,
    DraftPreviewResponse,
    DraftStage1Question,
)
from src.domain.draft_service import DraftService
from src.domain.draft_v1_contract import list_of_dicts
from src.domain.models import Draft
from src.infra.input_exceptions import InputMainDataSourceNotFoundError

router = APIRouter(tags=["draft"])

def _dedupe_candidates(values: list[str], *, limit: int = 300) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        if value.strip() == "" or value in seen:
            continue
        out.append(value)
        seen.add(value)
        if len(out) >= limit:
            break
    return out


def _required_variable_candidates(*, draft: Draft) -> list[str]:
    primary = [
        item.name for item in draft.column_candidates_v2 if item.role == "primary_dataset"
    ]
    candidates = _dedupe_candidates(primary)
    if len(candidates) == 0:
        candidates = _dedupe_candidates(list(draft.column_candidates))
    return candidates


@router.get(
    "/jobs/{job_id}/draft/preview",
    response_model=DraftPreviewResponse | DraftPreviewPendingResponse,
)
async def draft_preview(
    job_id: str,
    response: Response,
    main_data_source_id: str | None = Query(default=None),
    tenant_id: str = Depends(get_tenant_id),
    svc: DraftService = Depends(get_draft_service),
) -> DraftPreviewResponse | DraftPreviewPendingResponse:
    result = await svc.preview_v1(tenant_id=tenant_id, job_id=job_id)
    if result.pending is not None:
        if main_data_source_id is not None:
            raise InputMainDataSourceNotFoundError(main_data_source_id=main_data_source_id)
        response.status_code = 202
        return DraftPreviewPendingResponse(
            message=result.pending.message,
            retry_after_seconds=result.pending.retry_after_seconds,
            retry_until=result.pending.retry_until,
        )

    draft = result.draft
    assert draft is not None
    draft_dump = draft.model_dump(mode="json")

    if main_data_source_id is not None:
        known = {item.dataset_key for item in draft.data_sources}
        if main_data_source_id not in known:
            raise InputMainDataSourceNotFoundError(main_data_source_id=main_data_source_id)

    decision_raw = draft_dump.get("decision")
    decision: Literal["auto_freeze", "require_confirm", "require_confirm_with_downgrade"]
    if isinstance(decision_raw, str) and decision_raw in {
        "auto_freeze",
        "require_confirm",
        "require_confirm_with_downgrade",
    }:
        decision = cast(
            Literal["auto_freeze", "require_confirm", "require_confirm_with_downgrade"],
            decision_raw,
        )
    else:
        decision = "require_confirm"

    required_candidates = _required_variable_candidates(draft=draft)
    return DraftPreviewResponse(
        job_id=job_id,
        draft_text=draft.text,
        draft_id=str(draft_dump.get("draft_id", "")),
        decision=decision,
        risk_score=float(draft_dump.get("risk_score", 0.0)),
        outcome_var=draft.outcome_var,
        treatment_var=draft.treatment_var,
        controls=list(draft.controls),
        column_candidates=list(draft.column_candidates),
        column_candidates_v2=[
            DraftColumnCandidateV2(dataset_key=item.dataset_key, role=item.role, name=item.name)
            for item in draft.column_candidates_v2
        ],
        column_name_normalizations=[
            DraftColumnNameNormalization(
                dataset_key=item.dataset_key,
                role=item.role,
                original_name=item.original_name,
                normalized_name=item.normalized_name,
            )
            for item in draft.column_name_normalizations
        ],
        required_variables=[
            DraftRequiredVariable(
                field="__ID_VAR__",
                description="个体标识变量 (ID)",
                candidates=required_candidates,
            ),
            DraftRequiredVariable(
                field="__TIME_VAR__",
                description="时间变量 (Time)",
                candidates=required_candidates,
            ),
        ],
        data_quality_warnings=cast(
            list[DraftDataQualityWarning],
            list_of_dicts(draft_dump.get("data_quality_warnings")),
        ),
        stage1_questions=cast(
            list[DraftStage1Question],
            list_of_dicts(draft_dump.get("stage1_questions")),
        ),
        open_unknowns=cast(list[DraftOpenUnknown], list_of_dicts(draft_dump.get("open_unknowns"))),
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


@router.post("/jobs/{job_id}/draft/patch", response_model=DraftPatchResponse)
async def draft_patch(
    job_id: str,
    payload: DraftPatchRequest = Body(default_factory=DraftPatchRequest),
    tenant_id: str = Depends(get_tenant_id),
    svc: DraftService = Depends(get_draft_service),
) -> DraftPatchResponse:
    patched = svc.patch_v1(tenant_id=tenant_id, job_id=job_id, field_updates=payload.field_updates)
    draft_dump = patched.draft.model_dump(mode="json")
    return DraftPatchResponse(
        patched_fields=list(patched.patched_fields),
        remaining_unknowns_count=patched.remaining_unknowns_count,
        open_unknowns=list(draft_dump.get("open_unknowns", [])),
        draft_preview={
            "outcome_var": patched.draft.outcome_var,
            "treatment_var": patched.draft.treatment_var,
            "controls": list(patched.draft.controls),
        },
    )
