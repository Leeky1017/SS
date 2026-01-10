from __future__ import annotations

from src.domain.models import ArtifactKind, PlanStep, PlanStepType
from src.domain.plan_service_support import RUN_STATA_PRODUCES
from src.utils.json_types import JsonObject


def build_plan_steps(
    *,
    composition_mode: str,
    template_id: str,
    template_params: JsonObject,
    template_contract: JsonObject,
    primary_key: str,
    requirement_fingerprint: str,
    analysis_spec: JsonObject,
) -> list[PlanStep]:
    generate_step = PlanStep(
        step_id="generate_do",
        type=PlanStepType.GENERATE_STATA_DO,
        params={
            "composition_mode": composition_mode,
            "template_id": template_id,
            "template_params": template_params,
            "template_contract": template_contract,
            "input_bindings": {"primary_dataset": f"input:{primary_key}"},
            "products": [],
            "requirement_fingerprint": requirement_fingerprint,
            "analysis_spec": analysis_spec,
        },
        depends_on=[],
        produces=[ArtifactKind.STATA_DO],
    )
    run_step = PlanStep(
        step_id="run_stata",
        type=PlanStepType.RUN_STATA,
        params={
            "composition_mode": composition_mode,
            "timeout_seconds": 300,
            "products": [{"product_id": "summary_table", "kind": "table"}],
        },
        depends_on=["generate_do"],
        produces=RUN_STATA_PRODUCES,
    )
    return [generate_step, run_step]

