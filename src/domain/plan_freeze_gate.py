from __future__ import annotations

from collections.abc import Sequence

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


_VARIABLE_SELECTION_PARAMS = frozenset(
    {"__ID_VAR__", "__TIME_VAR__", "__PANELVAR__", "__CLUSTER_VAR__"}
)
_DRAFT_PATCH_PARAMS = frozenset(
    {"__NUMERIC_VARS__", "__CHECK_VARS__", "__DEPVAR__", "__INDEPVARS__"}
)


def _needs_variable_corrections(missing_params: Sequence[str]) -> bool:
    return any(item in _VARIABLE_SELECTION_PARAMS for item in missing_params)


def _needs_draft_patch(missing_fields: Sequence[str], missing_params: Sequence[str]) -> bool:
    if any(item.startswith("open_unknowns.") for item in missing_fields):
        return True
    return any(item in _DRAFT_PATCH_PARAMS for item in missing_params)


def _payload_schema_for(*, fields: Sequence[str]) -> dict[str, object]:
    schema: dict[str, object] = {"type": "object"}
    if len(fields) == 0:
        return schema
    schema["required"] = list(fields)
    schema["properties"] = {name: {"type": "object"} for name in fields}
    return schema


def _payload_schema_for_variable_corrections() -> dict[str, object]:
    return {
        "type": "object",
        "required": ["variable_corrections"],
        "properties": {
            "variable_corrections": {
                "type": "object",
                "additionalProperties": {"type": "string"},
            }
        },
    }


def _action_provide_answers(*, job_id: str) -> dict[str, object]:
    return {
        "action": "provide_answers",
        "type": "form",
        "label": "补全必答问题",
        "method": "POST",
        "path": f"/v1/jobs/{job_id}/plan/freeze",
        "fields": ["answers"],
        "payload_schema": _payload_schema_for(fields=["answers"]),
    }


def _action_provide_variable_corrections(*, job_id: str) -> dict[str, object]:
    return {
        "action": "provide_variable_corrections",
        "type": "form",
        "label": "选择缺失变量（ID/Time 等）",
        "method": "POST",
        "path": f"/v1/jobs/{job_id}/plan/freeze",
        "fields": ["variable_corrections"],
        "payload_schema": _payload_schema_for_variable_corrections(),
    }


def _action_patch_draft(*, job_id: str) -> dict[str, object]:
    return {
        "action": "patch_draft",
        "type": "form",
        "label": "补全草稿字段",
        "method": "POST",
        "path": f"/v1/jobs/{job_id}/draft/patch",
        "fields": ["field_updates"],
        "payload_schema": _payload_schema_for(fields=["field_updates"]),
    }


def _action_retry_freeze(*, job_id: str) -> dict[str, object]:
    return {
        "action": "retry_freeze",
        "type": "button",
        "label": "重试冻结计划",
        "method": "POST",
        "path": f"/v1/jobs/{job_id}/plan/freeze",
        "payload_schema": _payload_schema_for(fields=[]),
    }


def next_actions_for_plan_freeze_missing(
    *, job_id: str, missing_fields: list[str], missing_params: list[str]
) -> list[dict[str, object]]:
    needs_answers = any(item.startswith("stage1_questions.") for item in missing_fields)
    needs_variable_corrections = _needs_variable_corrections(missing_params)
    needs_patch = _needs_draft_patch(missing_fields, missing_params)

    actions: list[dict[str, object]] = []
    if needs_answers:
        actions.append(_action_provide_answers(job_id=job_id))
    if needs_variable_corrections:
        actions.append(_action_provide_variable_corrections(job_id=job_id))
    if needs_patch:
        actions.append(_action_patch_draft(job_id=job_id))
    actions.append(_action_retry_freeze(job_id=job_id))
    return actions
