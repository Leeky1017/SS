from __future__ import annotations

from src.domain.draft_confirm_blocking import confirm_blockers
from src.domain.models import Draft
from src.utils.json_types import JsonValue


def missing_draft_fields_for_plan_freeze(
    *, draft: Draft | None, answers: dict[str, JsonValue]
) -> list[str]:
    missing_question_ids, blocking_unknown_fields = confirm_blockers(draft=draft, answers=answers)
    missing: list[str] = []
    for question_id in missing_question_ids:
        if question_id.strip() != "":
            missing.append(f"stage1_questions.{question_id}")
    for field in blocking_unknown_fields:
        if field.strip() != "":
            missing.append(f"open_unknowns.{field}")
    return sorted(set(missing))


def next_actions_for_plan_freeze_missing(
    *, job_id: str, missing_fields: list[str], missing_params: list[str]
) -> list[dict[str, object]]:
    needs_answers = any(item.startswith("stage1_questions.") for item in missing_fields)
    needs_patch = len(missing_params) > 0 or any(
        item.startswith("open_unknowns.") for item in missing_fields
    )

    actions: list[dict[str, object]] = []
    if needs_answers:
        actions.append(
            {
                "action": "provide_answers",
                "method": "POST",
                "path": f"/v1/jobs/{job_id}/plan/freeze",
                "fields": ["answers"],
            }
        )
    if needs_patch:
        actions.append(
            {
                "action": "patch_draft",
                "method": "POST",
                "path": f"/v1/jobs/{job_id}/draft/patch",
                "fields": ["field_updates"],
            }
        )
    actions.append(
        {"action": "retry_freeze", "method": "POST", "path": f"/v1/jobs/{job_id}/plan/freeze"}
    )
    return actions
