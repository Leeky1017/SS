from __future__ import annotations

import json
from typing import cast

from src.domain.do_template_catalog import FamilySummary, TemplateSummary
from src.domain.do_template_selection_models import (
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.domain.do_template_selection_prompting_utils import (
    estimate_tokens,
    family_prompt_item,
    sha256_hex,
    template_prompt_item,
)
from src.utils.json_types import JsonObject

_SELECTION_ARTIFACT_BASE = "artifacts/do_template/selection"


def selection_artifact_paths() -> tuple[str, str, str]:
    stage1_rel = f"{_SELECTION_ARTIFACT_BASE}/stage1.json"
    candidates_rel = f"{_SELECTION_ARTIFACT_BASE}/candidates.json"
    stage2_rel = f"{_SELECTION_ARTIFACT_BASE}/stage2.json"
    return stage1_rel, candidates_rel, stage2_rel


def _candidate_token_estimate(items: list[dict[str, object]]) -> int:
    return sum(
        estimate_tokens(json.dumps(item, ensure_ascii=False, sort_keys=True)) for item in items
    )


def stage1_evidence_payload(
    *,
    job_id: str,
    requirement: str,
    families: tuple[FamilySummary, ...],
    stage1: Stage1FamilySelection | Stage1FamilySelectionV2,
    selected_family_ids: tuple[str, ...],
    max_families: int,
) -> JsonObject:
    return cast(
        JsonObject,
        {
            "schema_version": 1,
            "job_id": job_id,
            "stage": "stage1",
            "operation": "do_template.select_families",
            "requirement_fingerprint": sha256_hex(requirement.strip()),
            "max_families": int(max_families),
            "canonical_family_ids": [f.family_id for f in families],
            "family_summaries": [family_prompt_item(f) for f in families],
            "selection": stage1.model_dump(mode="json"),
            "selected_family_ids": list(selected_family_ids),
        },
    )


def candidates_evidence_payload(
    *,
    job_id: str,
    selected_family_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    token_budget: int,
    max_candidates: int,
) -> JsonObject:
    candidate_items = [template_prompt_item(t) for t in candidates]
    return cast(
        JsonObject,
        {
            "schema_version": 1,
            "job_id": job_id,
            "stage": "stage2_candidates",
            "selected_family_ids": list(selected_family_ids),
            "token_budget": int(token_budget),
            "max_candidates": int(max_candidates),
            "candidate_token_estimate": _candidate_token_estimate(candidate_items),
            "candidate_template_ids": [t.template_id for t in candidates],
            "candidates": candidate_items,
        },
    )


def stage2_evidence_payload(
    *,
    job_id: str,
    requirement: str,
    candidates: tuple[TemplateSummary, ...],
    stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2,
    selected_template_id: str,
    supplementary_template_ids: tuple[str, ...] = tuple(),
    primary_confidence: float | None = None,
    requires_user_confirmation: bool = False,
    used_manual_fallback: bool = False,
) -> JsonObject:
    return cast(
        JsonObject,
        {
            "schema_version": 1,
            "job_id": job_id,
            "stage": "stage2",
            "operation": "do_template.select_template",
            "requirement_fingerprint": sha256_hex(requirement.strip()),
            "candidate_template_ids": [t.template_id for t in candidates],
            "selection": stage2.model_dump(mode="json"),
            "selected_template_id": selected_template_id,
            "supplementary_template_ids": list(supplementary_template_ids),
            "primary_confidence": primary_confidence,
            "requires_user_confirmation": bool(requires_user_confirmation),
            "used_manual_fallback": bool(used_manual_fallback),
        },
    )
