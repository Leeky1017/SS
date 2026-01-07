from __future__ import annotations

import hashlib
import json
import re
from typing import Iterable, cast

from pydantic import ValidationError

from src.domain.do_template_catalog import FamilySummary, TemplateSummary
from src.domain.do_template_selection_models import Stage1FamilySelection, Stage2TemplateSelection
from src.infra.do_template_selection_exceptions import DoTemplateSelectionParseError
from src.utils.json_types import JsonObject

_WORD_RE = re.compile(r"[A-Za-z0-9_]+")
_SELECTION_ARTIFACT_BASE = "artifacts/do_template/selection"


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def estimate_tokens(text: str) -> int:
    stripped = text.strip()
    if stripped == "":
        return 0
    return max(1, len(stripped) // 4)


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


def family_prompt_item(family: FamilySummary) -> dict[str, object]:
    return {
        "family_id": family.family_id,
        "description": family.description,
        "capabilities": list(family.capabilities),
        "n_templates": len(family.template_ids),
    }


def template_prompt_item(template: TemplateSummary) -> dict[str, object]:
    return {
        "template_id": template.template_id,
        "family_id": template.family_id,
        "name": template.name[:80],
        "slug": template.slug[:80],
        "placeholders": list(template.placeholders)[:8],
        "output_types": list(template.output_types)[:8],
    }


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


def parse_stage1(text: str) -> Stage1FamilySelection:
    raw = _extract_json_object(text)
    try:
        return Stage1FamilySelection.model_validate_json(raw)
    except ValidationError as e:
        raise DoTemplateSelectionParseError(stage="stage1", reason=str(e)) from e


def parse_stage2(text: str) -> Stage2TemplateSelection:
    raw = _extract_json_object(text)
    try:
        return Stage2TemplateSelection.model_validate_json(raw)
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
    rules = [
        "RULES:",
        f"- Return JSON with schema_version=1 and families[] (max {max(1, int(max_families))}).",
        "- Each item must include: family_id, reason, confidence (0.0-1.0).",
        "- family_id MUST be in CANONICAL_FAMILY_IDS exactly.",
        "- Output JSON only (no markdown).",
        "",
        "OUTPUT_SCHEMA:",
        '{"schema_version":1,"families":[{"family_id":"<id>","reason":"...","confidence":0.7}]}',
        "",
        "USER_REQUIREMENT:",
        requirement.strip(),
        "",
        "FAMILY_SUMMARIES:",
        *[f"- {line}" for line in items],
        "",
    ]
    return "\n".join([*header, "", *rules])


def stage2_prompt(
    *,
    requirement: str,
    selected_family_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    token_budget: int,
    attempt: int,
    previous_error: str | None,
) -> str:
    candidate_ids = ", ".join(t.template_id for t in candidates)
    items = [
        json.dumps(template_prompt_item(t), ensure_ascii=False, sort_keys=True) for t in candidates
    ]
    header = [
        "TASK: Select exactly one do-template template_id from the candidates.",
        f"ATTEMPT: {attempt}",
        f"SELECTED_FAMILY_IDS: {', '.join(selected_family_ids)}",
        f"CANDIDATE_TEMPLATE_IDS: {candidate_ids}",
        f"CANDIDATE_TOKEN_BUDGET: {int(token_budget)}",
    ]
    if previous_error is not None and previous_error.strip() != "":
        header.append(f"PREVIOUS_ERROR: {previous_error.strip()}")
    rules = [
        "RULES:",
        "- Return JSON with schema_version=1 and template_id, reason, confidence (0.0-1.0).",
        "- template_id MUST be in CANDIDATE_TEMPLATE_IDS exactly.",
        "- Output JSON only (no markdown).",
        "",
        "OUTPUT_SCHEMA:",
        '{"schema_version":1,"template_id":"<id>","reason":"...","confidence":0.7}',
        "",
        "USER_REQUIREMENT:",
        requirement.strip(),
        "",
        "CANDIDATE_TEMPLATES:",
        *[f"- {line}" for line in items],
        "",
    ]
    return "\n".join([*header, "", *rules])


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
    stage1: Stage1FamilySelection,
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
    stage2: Stage2TemplateSelection,
    selected_template_id: str,
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
        },
    )
