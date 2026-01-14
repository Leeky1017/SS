from __future__ import annotations

import hashlib
from dataclasses import dataclass
from datetime import timedelta
from typing import cast

from src.domain.models import Draft, Job
from src.utils.json_types import JsonValue
from src.utils.time import utc_now


@dataclass(frozen=True)
class DraftPreviewPending:
    message: str
    retry_after_seconds: int
    retry_until: str


@dataclass(frozen=True)
class DraftPreviewResult:
    draft: Draft | None
    pending: DraftPreviewPending | None


@dataclass(frozen=True)
class DraftPatchResult:
    draft: Draft
    patched_fields: tuple[str, ...]
    remaining_unknowns_count: int


def is_v1_redeem_job(job_id: str) -> bool:
    return job_id.startswith("job_tc_")


def has_inputs(job: Job) -> bool:
    if job.inputs is None:
        return False
    rel_path = job.inputs.manifest_rel_path
    if rel_path is None:
        return False
    return rel_path.strip() != ""


def pending_inputs_upload_result() -> DraftPreviewResult:
    retry_after_seconds = 3
    retry_until = (utc_now() + timedelta(seconds=30)).isoformat()
    return DraftPreviewResult(
        draft=None,
        pending=DraftPreviewPending(
            message="pending_inputs_upload",
            retry_after_seconds=retry_after_seconds,
            retry_until=retry_until,
        ),
    )


def v1_contract_fields(*, job: Job, draft: Draft, candidates: list[str]) -> dict[str, JsonValue]:
    stage1_questions: list[JsonValue]
    unknowns: list[JsonValue]
    if is_v1_redeem_job(job.job_id):
        stage1_questions = [
            {
                "question_id": "analysis_goal",
                "question_text": "What is your analysis goal?",
                "question_type": "single_choice",
                "options": [
                    {"option_id": "descriptive", "label": "Descriptive", "value": "descriptive"},
                    {"option_id": "causal", "label": "Causal", "value": "causal"},
                ],
                "priority": 1,
            }
        ]
        unknowns = _v1_open_unknowns(draft=draft, candidates=candidates)
    else:
        stage1_questions = []
        unknowns = []
    return {
        "draft_id": draft_id(draft=draft),
        "decision": "require_confirm",
        "risk_score": 0.0,
        "status": "ready",
        "data_quality_warnings": [],
        "stage1_questions": stage1_questions,
        "open_unknowns": unknowns,
    }


def draft_id(*, draft: Draft) -> str:
    created_at = draft.created_at if isinstance(draft.created_at, str) else ""
    text = draft.text if isinstance(draft.text, str) else ""
    seed = f"{created_at}:{text}".encode("utf-8", errors="ignore")
    return "draft_" + hashlib.sha256(seed).hexdigest()[:16]


def list_of_dicts(value: object) -> list[dict[str, object]]:
    if not isinstance(value, list):
        return []
    items: list[dict[str, object]] = []
    for item in value:
        if isinstance(item, dict):
            items.append(item)
    return items


def _v1_open_unknowns(*, draft: Draft, candidates: list[str]) -> list[JsonValue]:
    unknowns: list[JsonValue] = []
    candidate_list = candidates[:20]
    candidate_values = [cast(JsonValue, item) for item in candidate_list]
    if draft.outcome_var is None or (
        isinstance(draft.outcome_var, str) and draft.outcome_var == ""
    ):
        unknowns.append(
            {
                "field": "outcome_var",
                "description": "Select outcome variable",
                "impact": "high",
                "blocking": True,
                "candidates": candidate_values,
            }
        )
    if draft.treatment_var is None or (
        isinstance(draft.treatment_var, str) and draft.treatment_var == ""
    ):
        unknowns.append(
            {
                "field": "treatment_var",
                "description": "Select treatment variable",
                "impact": "high",
                "blocking": True,
                "candidates": candidate_values,
            }
        )
    return unknowns
