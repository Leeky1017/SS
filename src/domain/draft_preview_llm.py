from __future__ import annotations

import json
import re
from collections.abc import Mapping
from dataclasses import dataclass
from json import JSONDecodeError
from typing import Any

from src.domain.models import Draft
from src.utils.json_types import JsonValue

_DRAFT_PREVIEW_COLUMNS_LIMIT = 50
_DRAFT_PREVIEW_SCHEMA_VERSION_V1 = 1
_DRAFT_PREVIEW_SCHEMA_VERSION_V2 = 2

_JSON_BLOCK_RE = re.compile(r"```(?:json)?\s*\n?(.*?)\n?```", re.DOTALL)

_DRAFT_PREVIEW_SCHEMA_HINT_V2 = {
    "schema_version": 2,
    "draft_text": "string (<= 3 sentences)",
    "outcome_var": "string|null",
    "treatment_var": "string|null",
    "controls": ["string", "..."],
    "time_var": "string|null (panel time index, e.g. year)",
    "entity_var": "string|null (panel entity id, e.g. firm_id)",
    "cluster_var": "string|null (SE clustering var)",
    "fixed_effects": ["string", "..."],
    "interaction_terms": ["string", "..."],
    "instrument_var": "string|null (IV instrument for treatment_var)",
    "analysis_hints": ["string", "..."],
    "default_overrides": {},
}

_DRAFT_PREVIEW_RULES_V2 = [
    "- Always output schema_version=2.",
    "- Use exact column names from COLUMN_CANDIDATES for existing variables; do not invent names.",
    "- If a variable is unclear or not present, return null (for strings) or [] (for arrays).",
    "- controls/fixed_effects/interaction_terms/analysis_hints must be JSON arrays of strings.",
    (
        "- fixed_effects should list FE dimensions (e.g., ['firm_id','year']); "
        "include entity/time FE when appropriate."
    ),
    (
        "- Panel: set entity_var and time_var if requirement implies panel "
        "(e.g., firm-year, person-month)."
    ),
    (
        "- DID: keep treatment_var as the treatment indicator; add the DID interaction in "
        "interaction_terms (e.g., 'treated#post'); include fixed_effects/cluster_var "
        "if specified."
    ),
    (
        "- IV: set instrument_var when requirement mentions an instrument "
        "for an endogenous regressor; add 'iv_2sls' "
        "or similar to analysis_hints."
    ),
    "- draft_text should be concise (<= 3 sentences).",
]


class DraftPreviewParseError(Exception):
    """Raised when draft preview LLM output cannot be parsed/validated."""

    def __init__(self, message: str, raw_text: str) -> None:
        super().__init__(message)
        self.raw_text = raw_text


@dataclass(frozen=True)
class DraftPreviewOutputV2:
    schema_version: int
    draft_text: str
    outcome_var: str | None
    treatment_var: str | None
    controls: list[str]
    time_var: str | None
    entity_var: str | None
    cluster_var: str | None
    fixed_effects: list[str]
    interaction_terms: list[str]
    instrument_var: str | None
    analysis_hints: list[str]
    default_overrides: dict[str, JsonValue]


def build_draft_preview_prompt(*, requirement: str, column_candidates: list[str]) -> str:
    requirement_text = requirement.strip()
    candidates = _normalized_candidates(column_candidates=column_candidates)
    candidates_json = json.dumps(candidates, ensure_ascii=False, sort_keys=False)

    schema_hint = {
        "draft_text": "string",
        "outcome_var": "string|null",
        "treatment_var": "string|null",
        "controls": ["string", "..."],
        "default_overrides": {},
    }
    schema_json = json.dumps(schema_hint, ensure_ascii=False, sort_keys=False)

    return "\n".join(
        [
            "You are an econometrics assistant for Stata.",
            "Task: extract the dependent variable, key explanatory variable, and controls.",
            "Return ONLY a valid JSON object (no markdown, no extra text).",
            "",
            f"REQUIREMENT:\n{requirement_text}",
            "",
            "COLUMN_CANDIDATES (use exact names when possible):",
            candidates_json,
            "",
            "OUTPUT_SCHEMA:",
            schema_json,
            "",
            "Rules:",
            "- If outcome_var or treatment_var is unclear, return null.",
            "- controls must be a JSON array of strings (may be empty).",
            "- default_overrides must be an object (may be empty).",
            "- draft_text should be concise (<= 3 sentences).",
        ]
    )


def build_draft_preview_prompt_v2(*, requirement: str, column_candidates: list[str]) -> str:
    requirement_text = requirement.strip()
    candidates = _normalized_candidates(column_candidates=column_candidates)
    candidates_json = json.dumps(candidates, ensure_ascii=False, sort_keys=False)

    schema_json = json.dumps(_DRAFT_PREVIEW_SCHEMA_HINT_V2, ensure_ascii=False, sort_keys=False)
    return "\n".join(
        [
            "You are an econometrics expert and Stata power user.",
            "Task: extract variables and econometric structure from the requirement and columns.",
            "Return ONLY a valid JSON object (no markdown, no extra text).",
            "",
            f"REQUIREMENT:\n{requirement_text}",
            "",
            "COLUMN_CANDIDATES (use exact names when possible):",
            candidates_json,
            "",
            "OUTPUT_SCHEMA (v2):",
            schema_json,
            "",
            "Rules:",
            *_DRAFT_PREVIEW_RULES_V2,
        ]
    )


def apply_structured_fields_from_llm_text(
    *,
    draft: Draft,
    strict: bool = False,
) -> tuple[Draft, bool]:
    try:
        parsed = parse_draft_preview_v2(draft.text)
    except DraftPreviewParseError:
        if strict:
            raise
        return draft, False
    updates = _draft_updates_from_output_v2(parsed)
    return draft.model_copy(update=updates), True


def parse_draft_preview_v2(text: str) -> DraftPreviewOutputV2:
    raw = text.strip()
    if "```" in raw:
        raw = _extract_json_from_markdown(raw)

    try:
        parsed = json.loads(raw)
    except JSONDecodeError as e:
        raise DraftPreviewParseError(f"Invalid JSON: {e}", raw_text=text) from e
    if not isinstance(parsed, Mapping):
        raise DraftPreviewParseError("Response must be a JSON object", raw_text=text)

    schema_version = _schema_version(parsed, raw_text=text)
    draft_text = _required_str(parsed, key="draft_text", raw_text=text)
    return DraftPreviewOutputV2(
        schema_version=schema_version,
        draft_text=draft_text,
        outcome_var=_optional_str(parsed, key="outcome_var", raw_text=text),
        treatment_var=_optional_str(parsed, key="treatment_var", raw_text=text),
        controls=_optional_str_list(parsed.get("controls"), key="controls", raw_text=text),
        time_var=_optional_str(parsed, key="time_var", raw_text=text),
        entity_var=_optional_str(parsed, key="entity_var", raw_text=text),
        cluster_var=_optional_str(parsed, key="cluster_var", raw_text=text),
        fixed_effects=_optional_str_list(
            parsed.get("fixed_effects"), key="fixed_effects", raw_text=text
        ),
        interaction_terms=_optional_str_list(
            parsed.get("interaction_terms"), key="interaction_terms", raw_text=text
        ),
        instrument_var=_optional_str(parsed, key="instrument_var", raw_text=text),
        analysis_hints=_optional_str_list(
            parsed.get("analysis_hints"), key="analysis_hints", raw_text=text
        ),
        default_overrides=_optional_json_object(
            parsed.get("default_overrides"), key="default_overrides", raw_text=text
        ),
    )


def _draft_updates_from_output_v2(output: DraftPreviewOutputV2) -> dict[str, Any]:
    return {
        "text": output.draft_text.strip(),
        "outcome_var": output.outcome_var,
        "treatment_var": output.treatment_var,
        "controls": list(output.controls),
        "time_var": output.time_var,
        "entity_var": output.entity_var,
        "cluster_var": output.cluster_var,
        "fixed_effects": list(output.fixed_effects),
        "interaction_terms": list(output.interaction_terms),
        "instrument_var": output.instrument_var,
        "analysis_hints": list(output.analysis_hints),
        "default_overrides": dict(output.default_overrides),
        "draft_preview_schema_version": output.schema_version,
    }


def _extract_json_from_markdown(text: str) -> str:
    match = _JSON_BLOCK_RE.search(text)
    if match is None:
        return text
    return match.group(1).strip()


def _schema_version(parsed: Mapping[str, object], *, raw_text: str) -> int:
    if "schema_version" not in parsed:
        return _DRAFT_PREVIEW_SCHEMA_VERSION_V1
    value = parsed.get("schema_version")
    if not isinstance(value, int):
        raise DraftPreviewParseError("'schema_version' must be an integer", raw_text=raw_text)
    if value not in (_DRAFT_PREVIEW_SCHEMA_VERSION_V1, _DRAFT_PREVIEW_SCHEMA_VERSION_V2):
        raise DraftPreviewParseError(f"Unsupported schema_version: {value}", raw_text=raw_text)
    return value


def _required_str(parsed: Mapping[str, object], *, key: str, raw_text: str) -> str:
    value = parsed.get(key)
    if not isinstance(value, str) or value.strip() == "":
        raise DraftPreviewParseError(f"Missing or empty '{key}' field", raw_text=raw_text)
    return value.strip()


def _optional_str(parsed: Mapping[str, object], *, key: str, raw_text: str) -> str | None:
    if key not in parsed:
        return None
    value = parsed.get(key)
    if value is None:
        return None
    if isinstance(value, str):
        cleaned = value.strip()
        return cleaned if cleaned != "" else None
    raise DraftPreviewParseError(f"'{key}' must be a string or null", raw_text=raw_text)


def _optional_str_list(value: object, *, key: str, raw_text: str) -> list[str]:
    if value is None:
        return []
    if not isinstance(value, list):
        raise DraftPreviewParseError(f"'{key}' must be a list of strings", raw_text=raw_text)
    cleaned: list[str] = []
    for item in value:
        if not isinstance(item, str):
            continue
        stripped = item.strip()
        if stripped != "":
            cleaned.append(stripped)
    return cleaned


def _optional_json_object(value: object, *, key: str, raw_text: str) -> dict[str, JsonValue]:
    if value is None:
        return {}
    if not isinstance(value, dict):
        raise DraftPreviewParseError(f"'{key}' must be an object", raw_text=raw_text)
    cleaned: dict[str, JsonValue] = {}
    for k, v in value.items():
        if isinstance(k, str) and k.strip() != "":
            cleaned[k] = v
    return cleaned


def _normalized_candidates(*, column_candidates: list[str]) -> list[str]:
    candidates = [c.strip() for c in column_candidates if isinstance(c, str) and c.strip() != ""]
    return candidates[:_DRAFT_PREVIEW_COLUMNS_LIMIT]
