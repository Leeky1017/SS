from __future__ import annotations

import json
from json import JSONDecodeError
from typing import Any, Mapping

from src.domain.models import Draft
from src.utils.json_types import JsonValue

_DRAFT_PREVIEW_COLUMNS_LIMIT = 50


def build_draft_preview_prompt(*, requirement: str, column_candidates: list[str]) -> str:
    requirement_text = requirement.strip()
    candidates = [c.strip() for c in column_candidates if isinstance(c, str) and c.strip() != ""]
    candidates = candidates[:_DRAFT_PREVIEW_COLUMNS_LIMIT]
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


def apply_structured_fields_from_llm_text(*, draft: Draft) -> tuple[Draft, bool]:
    parsed = _parse_llm_json_object(draft.text)
    if parsed is None:
        return draft, False
    updates = _draft_updates_from_parsed(parsed)
    if len(updates) == 0:
        return draft, True
    return draft.model_copy(update=updates), True


def _parse_llm_json_object(text: str) -> Mapping[str, object] | None:
    raw = text.strip()
    try:
        parsed = json.loads(raw)
    except JSONDecodeError:
        return None
    if not isinstance(parsed, Mapping):
        return None
    return parsed


def _draft_updates_from_parsed(parsed: Mapping[str, object]) -> dict[str, Any]:
    updates: dict[str, Any] = {}
    _maybe_update_draft_text(updates=updates, parsed=parsed)
    _maybe_update_optional_str(updates=updates, parsed=parsed, key="outcome_var")
    _maybe_update_optional_str(updates=updates, parsed=parsed, key="treatment_var")
    _maybe_update_controls(updates=updates, parsed=parsed)
    _maybe_update_default_overrides(updates=updates, parsed=parsed)
    return updates


def _maybe_update_draft_text(*, updates: dict[str, Any], parsed: Mapping[str, object]) -> None:
    draft_text = parsed.get("draft_text")
    if isinstance(draft_text, str) and draft_text.strip() != "":
        updates["text"] = draft_text.strip()


def _maybe_update_optional_str(
    *, updates: dict[str, Any], parsed: Mapping[str, object], key: str
) -> None:
    if key not in parsed:
        return
    value = parsed.get(key)
    if value is None:
        updates[key] = None
    elif isinstance(value, str):
        cleaned = value.strip()
        updates[key] = cleaned if cleaned != "" else None


def _maybe_update_controls(*, updates: dict[str, Any], parsed: Mapping[str, object]) -> None:
    if "controls" not in parsed:
        return
    controls = parsed.get("controls")
    if controls is None:
        updates["controls"] = []
    elif isinstance(controls, list):
        cleaned_controls: list[str] = []
        for item in controls:
            if isinstance(item, str):
                cleaned = item.strip()
                if cleaned != "":
                    cleaned_controls.append(cleaned)
        updates["controls"] = cleaned_controls


def _maybe_update_default_overrides(
    *, updates: dict[str, Any], parsed: Mapping[str, object]
) -> None:
    if "default_overrides" not in parsed:
        return
    default_overrides = parsed.get("default_overrides")
    if default_overrides is None:
        updates["default_overrides"] = {}
    elif isinstance(default_overrides, dict):
        cleaned_overrides: dict[str, JsonValue] = {}
        for key, value in default_overrides.items():
            if isinstance(key, str) and key.strip() != "":
                cleaned_overrides[key] = value
        updates["default_overrides"] = cleaned_overrides
