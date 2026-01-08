from __future__ import annotations

import json
from pathlib import Path

import pytest

from src.domain.composition_plan import CompositionMode, validate_composition_plan
from src.domain.models import LLMPlan, PlanStep, PlanStepType
from src.infra.plan_exceptions import PlanCompositionInvalidError


def _load_plan_fixture(filename: str) -> LLMPlan:
    path = Path(__file__).parent / "fixtures" / "composition_plans" / filename
    payload = json.loads(path.read_text(encoding="utf-8"))
    return LLMPlan.model_validate(payload)


def test_validate_composition_plan_with_merge_then_sequential_fixture_returns_mode() -> None:
    # Arrange
    plan = _load_plan_fixture("merge_then_sequential.json")

    # Act
    mode = validate_composition_plan(plan=plan, known_input_keys={"main", "controls"})

    # Assert
    assert mode == CompositionMode.MERGE_THEN_SEQUENTIAL


def test_validate_composition_plan_with_parallel_then_aggregate_fixture_returns_mode() -> None:
    # Arrange
    plan = _load_plan_fixture("parallel_then_aggregate.json")

    # Act
    mode = validate_composition_plan(plan=plan, known_input_keys={"a", "b"})

    # Assert
    assert mode == CompositionMode.PARALLEL_THEN_AGGREGATE


def test_validate_composition_plan_with_unknown_input_ref_raises_error() -> None:
    # Arrange
    plan = LLMPlan(
        plan_id="p1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="s1",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "sequential",
                    "template_id": "T01",
                    "input_bindings": {"primary_dataset": "input:unknown"},
                    "products": [],
                },
                depends_on=[],
                produces=[],
            )
        ],
    )

    # Act / Assert
    with pytest.raises(PlanCompositionInvalidError) as exc:
        validate_composition_plan(plan=plan, known_input_keys={"primary"})
    assert exc.value.error_code == "PLAN_COMPOSITION_INVALID"
    assert "unknown_input_dataset" in exc.value.message


def test_validate_composition_plan_with_duplicate_product_id_raises_error() -> None:
    # Arrange
    plan = LLMPlan(
        plan_id="p1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="s1",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "merge_then_sequential",
                    "template_id": "TA_merge_v1",
                    "input_bindings": {"primary_dataset": "input:primary"},
                    "products": [
                        {"product_id": "merged", "kind": "dataset"},
                        {"product_id": "merged", "kind": "dataset"},
                    ],
                },
                depends_on=[],
                produces=[],
            )
        ],
    )

    # Act / Assert
    with pytest.raises(PlanCompositionInvalidError) as exc:
        validate_composition_plan(plan=plan, known_input_keys={"primary"})
    assert exc.value.error_code == "PLAN_COMPOSITION_INVALID"
    assert "duplicate_product_id" in exc.value.message


def test_validate_composition_plan_with_mode_mismatch_raises_error() -> None:
    # Arrange
    plan = LLMPlan(
        plan_id="p1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="generate",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "sequential",
                    "template_id": "T01",
                    "input_bindings": {"primary_dataset": "input:primary"},
                    "products": [],
                },
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="run",
                type=PlanStepType.RUN_STATA,
                params={"composition_mode": "merge_then_sequential", "timeout_seconds": 300},
                depends_on=["generate"],
                produces=[],
            ),
        ],
    )

    # Act / Assert
    with pytest.raises(PlanCompositionInvalidError) as exc:
        validate_composition_plan(plan=plan, known_input_keys={"primary"})
    assert exc.value.error_code == "PLAN_COMPOSITION_INVALID"
    assert "composition_mode_mismatch" in exc.value.message
