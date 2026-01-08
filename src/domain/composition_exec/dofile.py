from __future__ import annotations

from collections.abc import Mapping

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import LLMPlan, PlanStep, PlanStepType
from src.domain.stata_runner import RunError
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError,
    DoFilePlanInvalidError,
    DoFileTemplateUnsupportedError,
)
from src.infra.plan_exceptions import PlanCompositionInvalidError


def generate_step_do_file_or_error(
    *,
    generator: DoFileGenerator,
    plan: LLMPlan,
    step: PlanStep,
    inputs_manifest: Mapping[str, object],
) -> str | RunError:
    if step.type != PlanStepType.GENERATE_STATA_DO:
        raise PlanCompositionInvalidError(reason="unsupported_step_type", step_id=step.step_id)

    step_for_generation = step.model_copy(update={"depends_on": []})
    mini_plan = LLMPlan(
        plan_id=f"{plan.plan_id}:{step.step_id}",
        rel_path=plan.rel_path,
        steps=[step_for_generation],
    )
    try:
        return generator.generate(plan=mini_plan, inputs_manifest=inputs_manifest).do_file
    except (
        DoFilePlanInvalidError,
        DoFileTemplateUnsupportedError,
        DoFileInputsManifestInvalidError,
    ) as e:
        return RunError(error_code=e.error_code, message=e.message)
