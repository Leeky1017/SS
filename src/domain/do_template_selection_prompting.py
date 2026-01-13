from __future__ import annotations

import json
import re
from typing import Iterable, cast

from pydantic import ValidationError

from src.domain.do_template_catalog import FamilySummary, TemplateSummary
from src.domain.do_template_selection_evidence_payloads import (  # noqa: F401
    candidates_evidence_payload,
    selection_artifact_paths,
    stage1_evidence_payload,
    stage2_evidence_payload,
)
from src.domain.do_template_selection_models import (
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.domain.do_template_selection_prompting_utils import (
    estimate_tokens,
    family_prompt_item,
    template_prompt_item,
)
from src.infra.do_template_selection_exceptions import DoTemplateSelectionParseError

_WORD_RE = re.compile(r"[A-Za-z0-9_]+")


def _stage2_prompt_header(
    *,
    attempt: int,
    selected_family_ids: tuple[str, ...],
    analysis_sequence: tuple[str, ...],
    requires_combination: bool,
    combination_reason: str,
    candidate_ids: str,
    token_budget: int,
    previous_error: str | None,
) -> list[str]:
    header = [
        (
            "TASK: Select a primary do-template plus optional supplementary templates "
            "from the candidates."
        ),
        f"ATTEMPT: {attempt}",
        f"SELECTED_FAMILY_IDS: {', '.join(selected_family_ids)}",
        f"ANALYSIS_SEQUENCE: {', '.join(analysis_sequence)}",
        f"REQUIRES_COMBINATION: {str(bool(requires_combination)).lower()}",
        f"COMBINATION_REASON: {combination_reason.strip()}",
        f"CANDIDATE_TEMPLATE_IDS: {candidate_ids}",
        f"CANDIDATE_TOKEN_BUDGET: {int(token_budget)}",
    ]
    if previous_error is not None and previous_error.strip() != "":
        header.append(f"PREVIOUS_ERROR: {previous_error.strip()}")
    return header


def _stage2_prompt_rules(*, requirement: str, items: list[str]) -> list[str]:
    return [
        "RULES:",
        "- Return JSON with schema_version=2.",
        "- primary_template_id MUST be in CANDIDATE_TEMPLATE_IDS exactly.",
        "- supplementary_templates[].template_id MUST be in CANDIDATE_TEMPLATE_IDS exactly.",
        "- Do not repeat a template_id (primary vs supplementary).",
        "- supplementary_templates[] may be empty if a single template is sufficient.",
        "- supplementary_templates[].sequence_order MUST start at 1 and be unique.",
        (
            "- Use supplementary templates for multi-stage needs (e.g., descriptive stats "
            "before regression)."
        ),
        "- Output JSON only (no markdown).",
        "",
        "OUTPUT_SCHEMA:",
        (
            '{"schema_version":2,'
            '"primary_template_id":"<id>",'
            '"primary_reason":"...",'
            '"primary_confidence":0.7,'
            '"supplementary_templates":['
            '{"template_id":"<id>","purpose":"...","sequence_order":1,"confidence":0.6}'
            "]}"
        ),
        "",
        "USER_REQUIREMENT:",
        requirement.strip(),
        "",
        "CANDIDATE_TEMPLATES:",
        *[f"- {line}" for line in items],
        "",
    ]


def _word_tokens(value: str) -> frozenset[str]:
    tokens = {m.group(0).lower() for m in _WORD_RE.finditer(value)}
    return frozenset(t for t in tokens if t.strip() != "")


def _template_score(*, requirement_tokens: frozenset[str], template: TemplateSummary) -> int:
    if not requirement_tokens:
        return 0
    haystack = " ".join(
        [
            template.template_id,
            template.family_id,
            template.slug,
            template.name,
            " ".join(template.placeholders),
            " ".join(template.output_types),
        ]
    )
    hay = _word_tokens(haystack)
    return sum(1 for t in requirement_tokens if t in hay)


def rank_templates(
    *,
    requirement: str,
    templates: Iterable[TemplateSummary],
) -> tuple[TemplateSummary, ...]:
    req_tokens = _word_tokens(requirement)
    scored = [
        (template, _template_score(requirement_tokens=req_tokens, template=template))
        for template in templates
    ]
    scored.sort(key=lambda x: (-x[1], x[0].template_id))
    return tuple(t for t, _ in scored)

def trim_templates(
    *,
    templates: tuple[TemplateSummary, ...],
    token_budget: int,
    max_candidates: int,
) -> tuple[TemplateSummary, ...]:
    if token_budget <= 0 or max_candidates <= 0:
        return tuple()
    selected: list[TemplateSummary] = []
    used = 0
    for template in templates[:max_candidates]:
        line = json.dumps(template_prompt_item(template), ensure_ascii=False, sort_keys=True)
        cost = estimate_tokens(line)
        if used + cost > token_budget:
            break
        selected.append(template)
        used += cost
        if len(selected) >= max_candidates:
            break
    return tuple(selected)


def _extract_json_object(text: str) -> str:
    value = text.strip()
    if value.startswith("{") and value.endswith("}"):
        return value
    start = value.find("{")
    end = value.rfind("}")
    if start == -1 or end == -1 or end <= start:
        raise DoTemplateSelectionParseError(stage="json_extract", reason="no_json_object_found")
    return value[start : end + 1]


def _loads_json_object(raw: str, *, stage: str) -> dict[str, object]:
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as e:
        raise DoTemplateSelectionParseError(stage=stage, reason=f"invalid_json:{e}") from e
    if not isinstance(value, dict):
        raise DoTemplateSelectionParseError(stage=stage, reason="json_not_object")
    return cast(dict[str, object], value)


def parse_stage1(text: str) -> Stage1FamilySelection | Stage1FamilySelectionV2:
    raw = _extract_json_object(text)
    payload = _loads_json_object(raw, stage="stage1_json")
    version = payload.get("schema_version")
    try:
        if isinstance(version, int) and version == 2:
            return Stage1FamilySelectionV2.model_validate(payload)
        return Stage1FamilySelection.model_validate(payload)
    except ValidationError as e:
        raise DoTemplateSelectionParseError(stage="stage1", reason=str(e)) from e


def parse_stage2(text: str) -> Stage2TemplateSelection | Stage2TemplateSelectionV2:
    raw = _extract_json_object(text)
    payload = _loads_json_object(raw, stage="stage2_json")
    version = payload.get("schema_version")
    try:
        if isinstance(version, int) and version == 2:
            return Stage2TemplateSelectionV2.model_validate(payload)
        return Stage2TemplateSelection.model_validate(payload)
    except ValidationError as e:
        raise DoTemplateSelectionParseError(stage="stage2", reason=str(e)) from e


def stage1_prompt(
    *,
    requirement: str,
    families: tuple[FamilySummary, ...],
    max_families: int,
    attempt: int,
    previous_error: str | None,
) -> str:
    canonical_ids = ", ".join(f.family_id for f in families)
    items = [
        json.dumps(family_prompt_item(f), ensure_ascii=False, sort_keys=True) for f in families
    ]
    header = [
        "TASK: Select canonical do-template family IDs for the user requirement.",
        f"ATTEMPT: {attempt}",
        f"CANONICAL_FAMILY_IDS: {canonical_ids}",
    ]
    if previous_error is not None and previous_error.strip() != "":
        header.append(f"PREVIOUS_ERROR: {previous_error.strip()}")
    rules = _stage1_prompt_rules(
        requirement=requirement,
        items=items,
        max_families=int(max_families),
    )
    return "\n".join([*header, "", *rules])


_STAGE1_OUTPUT_SCHEMA = (
    '{"schema_version":2,'
    '"families":[{"family_id":"<id>","reason":"...","confidence":0.7}],'  # noqa: ISC003
    '"requires_combination":true,'
    '"combination_reason":"...",'
    '"analysis_sequence":["<family_id_1>","<family_id_2>"]}'
)


def _stage1_prompt_rules(*, requirement: str, items: list[str], max_families: int) -> list[str]:
    max_allowed = max(1, int(max_families))
    return [
        "RULES:",
        f"- Return JSON with schema_version=2 and families[] (max {max_allowed}).",
        "- Each family item must include: family_id, reason, confidence (0.0-1.0).",
        "- family_id MUST be in CANONICAL_FAMILY_IDS exactly.",
        (
            "- Determine if multiple templates are required (multi-stage analysis "
            "or multiple distinct outputs)."
        ),
        (
            "- If multiple templates are required: set requires_combination=true and "
            "explain in combination_reason."
        ),
        (
            "- Always provide analysis_sequence[] as the recommended analysis order "
            "(prefer canonical family IDs)."
        ),
        "- Output JSON only (no markdown).",
        "",
        "OUTPUT_SCHEMA:",
        _STAGE1_OUTPUT_SCHEMA,
        "",
        "USER_REQUIREMENT:",
        requirement.strip(),
        "",
        "FAMILY_SUMMARIES:",
        *[f"- {line}" for line in items],
        "",
    ]


def stage2_prompt(
    *,
    requirement: str,
    selected_family_ids: tuple[str, ...],
    analysis_sequence: tuple[str, ...] = tuple(),
    requires_combination: bool = False,
    combination_reason: str = "",
    candidates: tuple[TemplateSummary, ...],
    token_budget: int,
    attempt: int,
    previous_error: str | None,
) -> str:
    candidate_ids = ", ".join(t.template_id for t in candidates)
    items = [
        json.dumps(template_prompt_item(t), ensure_ascii=False, sort_keys=True) for t in candidates
    ]
    header = _stage2_prompt_header(
        attempt=attempt,
        selected_family_ids=selected_family_ids,
        analysis_sequence=analysis_sequence,
        requires_combination=requires_combination,
        combination_reason=combination_reason,
        candidate_ids=candidate_ids,
        token_budget=int(token_budget),
        previous_error=previous_error,
    )
    rules = _stage2_prompt_rules(requirement=requirement, items=items)
    return "\n".join([*header, "", *rules])
