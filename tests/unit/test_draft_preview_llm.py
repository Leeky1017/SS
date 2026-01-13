from __future__ import annotations

import json

import pytest

from src.domain.draft_preview_llm import (
    DraftPreviewParseError,
    apply_structured_fields_from_llm_text,
    parse_draft_preview_v2,
)
from src.domain.models import Draft
from src.utils.time import utc_now


def test_parse_draft_preview_v2_with_panel_data_returns_expected_fields() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "Estimate policy effect on y with controls using firm-year panel FE.",
        "outcome_var": "y",
        "treatment_var": "policy",
        "controls": ["x1", "x2"],
        "time_var": "year",
        "entity_var": "firm_id",
        "cluster_var": "firm_id",
        "fixed_effects": ["firm_id", "year"],
        "interaction_terms": [],
        "instrument_var": None,
        "analysis_hints": ["panel_twfe", "cluster_se:firm_id"],
        "default_overrides": {"vce": "cluster firm_id"},
    }

    # Act
    parsed = parse_draft_preview_v2(json.dumps(payload))

    # Assert
    assert parsed.schema_version == 2
    assert parsed.outcome_var == "y"
    assert parsed.treatment_var == "policy"
    assert parsed.controls == ["x1", "x2"]
    assert parsed.time_var == "year"
    assert parsed.entity_var == "firm_id"
    assert parsed.cluster_var == "firm_id"
    assert parsed.fixed_effects == ["firm_id", "year"]
    assert parsed.interaction_terms == []
    assert parsed.instrument_var is None
    assert parsed.analysis_hints == ["panel_twfe", "cluster_se:firm_id"]


def test_parse_draft_preview_v2_with_did_scenario_returns_interaction_terms() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "DID: estimate treated x post effect on y with controls.",
        "outcome_var": "y",
        "treatment_var": "treated",
        "controls": ["c1", "c2"],
        "time_var": "year",
        "entity_var": "firm_id",
        "cluster_var": "firm_id",
        "fixed_effects": ["firm_id", "year"],
        "interaction_terms": ["treated#post"],
        "instrument_var": None,
        "analysis_hints": ["did_twfe"],
        "default_overrides": {},
    }

    # Act
    parsed = parse_draft_preview_v2(json.dumps(payload))

    # Assert
    assert parsed.schema_version == 2
    assert parsed.treatment_var == "treated"
    assert parsed.interaction_terms == ["treated#post"]
    assert parsed.fixed_effects == ["firm_id", "year"]
    assert parsed.cluster_var == "firm_id"


def test_parse_draft_preview_v2_with_iv_scenario_returns_instrument_var() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "IV/2SLS: instrument x_endog with z for outcome y.",
        "outcome_var": "y",
        "treatment_var": "x_endog",
        "instrument_var": "z",
        "controls": ["c1", "c2"],
        "cluster_var": "region",
        "analysis_hints": ["iv_2sls"],
        "default_overrides": {},
    }

    # Act
    parsed = parse_draft_preview_v2(json.dumps(payload))

    # Assert
    assert parsed.schema_version == 2
    assert parsed.treatment_var == "x_endog"
    assert parsed.instrument_var == "z"
    assert parsed.controls == ["c1", "c2"]
    assert parsed.cluster_var == "region"
    assert parsed.fixed_effects == []
    assert parsed.interaction_terms == []


def test_parse_draft_preview_v2_with_v1_payload_defaults_v2_fields() -> None:
    # Arrange
    payload = {
        "draft_text": "Estimate x on y with controls.",
        "outcome_var": "y",
        "treatment_var": "x",
        "controls": ["c1"],
        "default_overrides": {"alpha": 0.05},
    }

    # Act
    parsed = parse_draft_preview_v2(json.dumps(payload))

    # Assert
    assert parsed.schema_version == 1
    assert parsed.outcome_var == "y"
    assert parsed.treatment_var == "x"
    assert parsed.controls == ["c1"]
    assert parsed.time_var is None
    assert parsed.entity_var is None
    assert parsed.cluster_var is None
    assert parsed.fixed_effects == []
    assert parsed.interaction_terms == []
    assert parsed.instrument_var is None
    assert parsed.analysis_hints == []


def test_parse_draft_preview_v2_with_missing_optional_fields_defaults_to_empty_values() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "Minimal schema: only draft_text and null vars.",
        "outcome_var": None,
        "treatment_var": None,
    }

    # Act
    parsed = parse_draft_preview_v2(json.dumps(payload))

    # Assert
    assert parsed.schema_version == 2
    assert parsed.controls == []
    assert parsed.fixed_effects == []
    assert parsed.interaction_terms == []
    assert parsed.analysis_hints == []
    assert parsed.default_overrides == {}


def test_parse_draft_preview_v2_with_invalid_input_raises_draft_preview_parse_error() -> None:
    # Arrange / Act / Assert
    with pytest.raises(DraftPreviewParseError):
        parse_draft_preview_v2("not json")


def test_parse_draft_preview_v2_with_invalid_fixed_effects_type_raises_error() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "Bad schema: fixed_effects should be a list.",
        "fixed_effects": "firm_id",
    }

    # Act / Assert
    with pytest.raises(DraftPreviewParseError):
        parse_draft_preview_v2(json.dumps(payload))


def test_parse_draft_preview_v2_with_markdown_json_block_parses_successfully() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "Parse fenced JSON.",
        "outcome_var": "y",
        "treatment_var": "x",
        "controls": [],
        "default_overrides": {},
    }
    fenced = "```json\n" + json.dumps(payload) + "\n```"

    # Act
    parsed = parse_draft_preview_v2(fenced)

    # Assert
    assert parsed.schema_version == 2
    assert parsed.outcome_var == "y"
    assert parsed.treatment_var == "x"


def test_apply_structured_fields_from_llm_text_with_v2_payload_updates_draft_fields() -> None:
    # Arrange
    payload = {
        "schema_version": 2,
        "draft_text": "Estimate policy effect on y with firm and year FE.",
        "outcome_var": "y",
        "treatment_var": "policy",
        "controls": ["x1"],
        "time_var": "year",
        "entity_var": "firm_id",
        "fixed_effects": ["firm_id", "year"],
        "analysis_hints": ["panel_twfe"],
        "default_overrides": {},
    }
    draft = Draft(text=json.dumps(payload), created_at=utc_now().isoformat())

    # Act
    updated, ok = apply_structured_fields_from_llm_text(draft=draft)
    updated_dump = updated.model_dump(mode="json")

    # Assert
    assert ok is True
    assert updated.text == "Estimate policy effect on y with firm and year FE."
    assert updated.outcome_var == "y"
    assert updated.treatment_var == "policy"
    assert updated.controls == ["x1"]
    assert updated_dump.get("time_var") == "year"
    assert updated_dump.get("entity_var") == "firm_id"
    assert updated_dump.get("fixed_effects") == ["firm_id", "year"]
    assert updated_dump.get("analysis_hints") == ["panel_twfe"]
    assert updated_dump.get("draft_preview_schema_version") == 2
