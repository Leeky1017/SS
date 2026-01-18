from __future__ import annotations

from collections.abc import Mapping, Sequence

from src.domain.models import Draft

_MISSING_PARAM_NEEDS_CANDIDATES = frozenset(
    {
        "__CHECK_VARS__",
        "__CLUSTER_VAR__",
        "__DEPVAR__",
        "__ID_VAR__",
        "__INDEPVARS__",
        "__NUMERIC_VARS__",
        "__PANELVAR__",
        "__TIME_VAR__",
    }
)
_MISSING_PARAM_VARIABLE_SELECTION = frozenset(
    {"__ID_VAR__", "__TIME_VAR__", "__PANELVAR__", "__CLUSTER_VAR__"}
)
_MISSING_PARAM_DRAFT_PATCH = frozenset(
    {"__NUMERIC_VARS__", "__CHECK_VARS__", "__DEPVAR__", "__INDEPVARS__"}
)


def _dedupe(values: Sequence[str], *, limit: int) -> list[str]:
    seen: set[str] = set()
    out: list[str] = []
    for value in values:
        candidate = value.strip()
        if candidate == "" or candidate in seen:
            continue
        out.append(candidate)
        seen.add(candidate)
        if len(out) >= limit:
            break
    return out


def _column_candidates(*, draft: Draft | None, limit: int = 300) -> list[str]:
    if draft is None:
        return []
    primary = [item.name for item in draft.column_candidates_v2 if item.role == "primary_dataset"]
    candidates = _dedupe(primary, limit=limit)
    if len(candidates) > 0:
        return candidates
    return _dedupe(list(draft.column_candidates), limit=limit)


def missing_fields_detail_for_plan_freeze(
    *, draft: Draft | None, missing_fields: Sequence[str]
) -> list[dict[str, object]]:
    if draft is None:
        return []
    questions = {q.question_id: q for q in draft.stage1_questions if q.question_id.strip() != ""}
    unknowns = {u.field: u for u in draft.open_unknowns if u.field.strip() != ""}

    details: list[dict[str, object]] = []
    for field in sorted({item for item in missing_fields if item.strip() != ""}):
        if field.startswith("stage1_questions."):
            question_id = field.split(".", 1)[1]
            question = questions.get(question_id)
            details.append(
                {
                    "field": field,
                    "description": "" if question is None else question.question_text,
                    "candidates": []
                    if question is None
                    else [opt.label for opt in question.options if opt.label.strip() != ""],
                }
            )
            continue
        if field.startswith("open_unknowns."):
            unknown_field = field.split(".", 1)[1]
            unknown = unknowns.get(unknown_field)
            details.append(
                {
                    "field": field,
                    "description": "" if unknown is None else unknown.description,
                    "candidates": [] if unknown is None else list(unknown.candidates),
                }
            )
    return details


def _param_description_map(meta: Mapping[str, object]) -> dict[str, str]:
    raw = meta.get("parameters", [])
    if not isinstance(raw, list):
        return {}
    out: dict[str, str] = {}
    for item in raw:
        if not isinstance(item, Mapping):
            continue
        name = item.get("name")
        desc = item.get("description")
        if not isinstance(name, str) or name.strip() == "":
            continue
        if not isinstance(desc, str) or desc.strip() == "":
            continue
        out[name] = desc.strip()
    return out


def missing_params_detail_for_plan_freeze(
    *,
    draft: Draft | None,
    missing_params: Sequence[str],
    template_meta: Mapping[str, object],
) -> list[dict[str, object]]:
    desc_map = _param_description_map(template_meta)
    candidates = _column_candidates(draft=draft)

    details: list[dict[str, object]] = []
    for param in sorted({item for item in missing_params if item.strip() != ""}):
        details.append(
            {
                "param": param,
                "description": desc_map.get(param, ""),
                "candidates": candidates if param in _MISSING_PARAM_NEEDS_CANDIDATES else [],
            }
        )
    return details


def action_message_for_plan_freeze_missing(
    *, missing_fields: Sequence[str], missing_params: Sequence[str]
) -> str:
    needs_answers = any(item.startswith("stage1_questions.") for item in missing_fields)
    needs_variable_selection = any(
        item in _MISSING_PARAM_VARIABLE_SELECTION for item in missing_params
    )
    needs_draft_patch = any(item.startswith("open_unknowns.") for item in missing_fields) or any(
        item in _MISSING_PARAM_DRAFT_PATCH for item in missing_params
    )

    parts: list[str] = []
    if needs_answers:
        parts.append("补全必答问题")
    if needs_variable_selection:
        parts.append("选择缺失变量")
    if needs_draft_patch:
        parts.append("补全草稿字段")
    if len(parts) == 0:
        return "请补全缺失项后重试冻结计划。"
    return "请先" + "、".join(parts) + "，然后重试冻结计划。"
