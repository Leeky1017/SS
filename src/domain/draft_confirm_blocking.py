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
    if len(draft.stage1_questions) == 0:
        return []
    missing: list[str] = []
    for question in draft.stage1_questions:
        question_id = question.question_id
        if question_id.strip() == "":
            continue
        if not _has_selected_answer(answers.get(question_id)):
            missing.append(question_id)
    return missing


def _blocking_unknown_fields(*, draft: Draft | None) -> list[str]:
    if draft is None:
        return []
    if len(draft.open_unknowns) == 0:
        return []
    fields: list[str] = []
    for item in draft.open_unknowns:
        field = item.field
        if field.strip() == "":
            continue
        impact = item.impact
        blocking = item.blocking
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
