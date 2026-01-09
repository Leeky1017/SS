from __future__ import annotations

import re
from collections.abc import Mapping

from src.domain.models import Draft
from src.utils.json_types import JsonValue

_TOKEN_CHAR_CLASS = r"[A-Za-z0-9_]"


def clean_variable_corrections(raw: Mapping[str, str]) -> dict[str, str]:
    cleaned: dict[str, str] = {}
    for old, new in raw.items():
        old_norm = old.strip()
        new_norm = new.strip()
        if old_norm == "" or new_norm == "":
            continue
        if old_norm == new_norm:
            continue
        cleaned[old_norm] = new_norm
    return cleaned


def apply_variable_corrections_text(value: str, corrections: Mapping[str, str]) -> str:
    out = value
    for old in sorted(corrections.keys()):
        out = _replace_token_boundary(out, old=old, new=corrections[old])
    return out


def _replace_token_boundary(value: str, *, old: str, new: str) -> str:
    try:
        pattern = re.compile(rf"(?<!{_TOKEN_CHAR_CLASS}){re.escape(old)}(?!{_TOKEN_CHAR_CLASS})")
    except re.error:
        return value.replace(old, new)
    return pattern.sub(new, value)


def apply_variable_corrections_json_value(
    value: JsonValue, corrections: Mapping[str, str]
) -> JsonValue:
    if isinstance(value, str):
        return apply_variable_corrections_text(value, corrections)
    if isinstance(value, list):
        return [apply_variable_corrections_json_value(item, corrections) for item in value]
    if isinstance(value, dict):
        updated: dict[str, JsonValue] = {}
        for key, item in value.items():
            updated[key] = apply_variable_corrections_json_value(item, corrections)
        return updated
    return value


def apply_variable_corrections_dict_values(
    value: Mapping[str, JsonValue], corrections: Mapping[str, str]
) -> dict[str, JsonValue]:
    updated: dict[str, JsonValue] = {}
    for key, item in value.items():
        updated[key] = apply_variable_corrections_json_value(item, corrections)
    return updated


def apply_variable_corrections_to_draft(draft: Draft, corrections: Mapping[str, str]) -> Draft:
    if not corrections:
        return draft
    updated_outcome = (
        None
        if draft.outcome_var is None
        else apply_variable_corrections_text(draft.outcome_var, corrections)
    )
    updated_treatment = (
        None
        if draft.treatment_var is None
        else apply_variable_corrections_text(draft.treatment_var, corrections)
    )
    updated_controls: list[str] = []
    for item in draft.controls:
        updated_controls.append(apply_variable_corrections_text(item, corrections))
    updated_overrides = apply_variable_corrections_dict_values(draft.default_overrides, corrections)
    return draft.model_copy(
        update={
            "text": apply_variable_corrections_text(draft.text, corrections),
            "outcome_var": updated_outcome,
            "treatment_var": updated_treatment,
            "controls": updated_controls,
            "default_overrides": updated_overrides,
        }
    )
