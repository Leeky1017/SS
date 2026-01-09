from __future__ import annotations

from src.domain.models import Draft
from src.utils.json_types import JsonValue


def confirm_blockers(
    *,
    draft: Draft | None,
    answers: dict[str, JsonValue],
) -> tuple[list[str], list[str]]:
    missing_question_ids = _missing_stage1_answers(draft=draft, answers=answers)
    blocking_unknown_fields = _blocking_unknown_fields(draft=draft)
    return missing_question_ids, blocking_unknown_fields


def _missing_stage1_answers(
    *,
    draft: Draft | None,
    answers: dict[str, JsonValue],
) -> list[str]:
    if draft is None:
        return []
    raw = draft.model_dump().get("stage1_questions")
    if not isinstance(raw, list) or len(raw) == 0:
        return []
    missing: list[str] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        question_id = item.get("question_id")
        if not isinstance(question_id, str) or question_id.strip() == "":
            continue
        if not _has_selected_answer(answers.get(question_id)):
            missing.append(question_id)
    return missing


def _blocking_unknown_fields(*, draft: Draft | None) -> list[str]:
    if draft is None:
        return []
    raw = draft.model_dump().get("open_unknowns")
    if not isinstance(raw, list) or len(raw) == 0:
        return []
    fields: list[str] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        field = item.get("field")
        if not isinstance(field, str) or field.strip() == "":
            continue
        impact = item.get("impact")
        blocking = item.get("blocking")
        is_blocking = blocking is True or impact in {"high", "critical"}
        if is_blocking:
            fields.append(field)
    return fields


def _has_selected_answer(value: JsonValue | None) -> bool:
    if value is None:
        return False
    if isinstance(value, str):
        return value.strip() != ""
    if isinstance(value, list):
        return any(_has_selected_answer(item) for item in value)
    return True

