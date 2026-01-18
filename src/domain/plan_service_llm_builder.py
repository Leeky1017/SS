from __future__ import annotations

from dataclasses import dataclass

from src.domain import do_template_plan_support
from src.domain.composition_plan import validate_composition_plan
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import (
    ArtifactKind,
    Job,
    JobConfirmation,
    LLMPlan,
    PlanSource,
    PlanStep,
    is_do_generation_step_type,
)
from src.domain.plan_contract import analysis_spec_from_draft
from src.domain.plan_generation_llm import (
    PlanGenerationParseError,
    build_plan_generation_prompt,
    parse_plan_generation_result,
)
from src.domain.plan_id_support import normalize_whitespace, sha256_hex
from src.domain.plan_routing import choose_composition_mode
from src.domain.plan_service_llm_support import (
    build_plan_generation_input,
    complete_text_sync,
    selected_templates_for_plan_generation,
)
from src.domain.plan_service_support import known_input_keys
from src.domain.plan_template_contract_builder import build_plan_template_contract
from src.utils.json_types import JsonObject

_PLAN_GENERATION_OP = "plan.generate"


def _execution_context(
    *,
    job: Job,
    requirement_norm: str,
    workspace: JobWorkspaceStore,
) -> tuple[set[str], str, str]:
    input_keys = known_input_keys(workspace=workspace, job=job)
    primary_key = "primary" if "primary" in input_keys else sorted(input_keys)[0]
    composition_mode = choose_composition_mode(requirement=requirement_norm, input_keys=input_keys)
    return input_keys, primary_key, composition_mode.value


def _analysis_context(
    *,
    job: Job,
    confirmation: JobConfirmation,
) -> tuple[str, str, JsonObject, list[str]]:
    requirement = "" if confirmation.requirement is None else confirmation.requirement
    requirement_norm = normalize_whitespace(requirement)
    requirement_fingerprint = sha256_hex(requirement_norm)
    analysis_spec = analysis_spec_from_draft(job=job)
    analysis_vars = do_template_plan_support.analysis_vars_from_analysis_spec(analysis_spec)
    return requirement_norm, requirement_fingerprint, analysis_spec, analysis_vars


@dataclass(frozen=True)
class _LLMStepsResult:
    requirement_norm: str
    requirement_fingerprint: str
    analysis_spec: JsonObject
    analysis_vars: list[str]
    steps: list[PlanStep]


@dataclass(frozen=True)
class _StepBuildContext:
    job: Job
    composition_mode: str
    primary_key: str
    requirement_fingerprint: str
    analysis_spec: JsonObject
    analysis_vars: list[str]
    variable_corrections: dict[str, str]
    default_template_id: str
    do_template_repo: DoTemplateRepository


def _generate_llm_steps(
    *,
    tenant_id: str,
    job: Job,
    confirmation: JobConfirmation,
    llm: LLMClient,
    workspace: JobWorkspaceStore,
    primary_template_id: str,
    max_steps: int,
) -> _LLMStepsResult:
    requirement_norm, requirement_fingerprint, analysis_spec, analysis_vars = _analysis_context(
        job=job, confirmation=confirmation
    )
    selected_templates = selected_templates_for_plan_generation(
        tenant_id=tenant_id,
        job=job,
        primary_template_id=primary_template_id,
        workspace=workspace,
    )
    plan_input = build_plan_generation_input(
        job=job,
        requirement=requirement_norm,
        selected_templates=selected_templates,
        max_steps=int(max_steps),
    )
    prompt = build_plan_generation_prompt(plan_input=plan_input)
    text = complete_text_sync(llm=llm, job=job, operation=_PLAN_GENERATION_OP, prompt=prompt)
    llm_steps = parse_plan_generation_result(
        text=text,
        max_steps=plan_input.constraints.max_steps,
        selected_templates=selected_templates,
    )
    return _LLMStepsResult(
        requirement_norm=requirement_norm,
        requirement_fingerprint=requirement_fingerprint,
        analysis_spec=analysis_spec,
        analysis_vars=analysis_vars,
        steps=llm_steps,
    )


def _execution_step_from_llm_step(
    *,
    ctx: _StepBuildContext,
    llm_step: PlanStep,
) -> PlanStep:
    if not is_do_generation_step_type(llm_step.type):
        raise PlanGenerationParseError(
            f"unsupported step type for execution: {llm_step.type.value}",
            raw_text="",
            error_code="PLAN_GEN_UNSUPPORTED_STEP_TYPE",
        )
    template_id = ctx.default_template_id
    raw_template_id = llm_step.params.get("template_id")
    if isinstance(raw_template_id, str) and raw_template_id.strip() != "":
        template_id = raw_template_id
    template_params = do_template_plan_support.template_params_for(
        template_id=template_id,
        analysis_spec=ctx.analysis_spec,
        variable_corrections=ctx.variable_corrections,
    )
    contract = build_plan_template_contract(
        repo=ctx.do_template_repo,
        job_id=ctx.job.job_id,
        template_id=template_id,
        template_params=template_params,
    )
    return PlanStep(
        step_id=llm_step.step_id,
        type=llm_step.type,
        purpose=llm_step.purpose,
        fallback_step_id=llm_step.fallback_step_id,
        params={
            "composition_mode": ctx.composition_mode,
            "template_id": template_id,
            "template_params": template_params,
            "template_contract": contract,
            "input_bindings": {"primary_dataset": f"input:{ctx.primary_key}"},
            "products": [],
            "requirement_fingerprint": ctx.requirement_fingerprint,
            "analysis_spec": ctx.analysis_spec,
        },
        depends_on=list(llm_step.depends_on),
        produces=[ArtifactKind.STATA_DO],
    )


def generate_plan_with_llm(
    *,
    tenant_id: str,
    job: Job,
    confirmation: JobConfirmation,
    plan_id: str,
    llm: LLMClient,
    workspace: JobWorkspaceStore,
    do_template_repo: DoTemplateRepository,
    primary_template_id: str,
    max_steps: int,
) -> LLMPlan:
    llm_result = _generate_llm_steps(
        tenant_id=tenant_id,
        job=job,
        confirmation=confirmation,
        llm=llm,
        workspace=workspace,
        primary_template_id=primary_template_id,
        max_steps=max_steps,
    )

    input_keys, primary_key, composition_mode = _execution_context(
        job=job,
        requirement_norm=llm_result.requirement_norm,
        workspace=workspace,
    )
    ctx = _StepBuildContext(
        job=job,
        composition_mode=composition_mode,
        primary_key=primary_key,
        requirement_fingerprint=llm_result.requirement_fingerprint,
        analysis_spec=llm_result.analysis_spec,
        analysis_vars=llm_result.analysis_vars,
        variable_corrections=dict(confirmation.variable_corrections),
        default_template_id=primary_template_id,
        do_template_repo=do_template_repo,
    )
    steps: list[PlanStep] = []
    for step in llm_result.steps:
        steps.append(_execution_step_from_llm_step(ctx=ctx, llm_step=step))

    plan = LLMPlan(
        plan_id=plan_id,
        rel_path="artifacts/plan.json",
        plan_source=PlanSource.LLM,
        steps=steps,
    )
    validate_composition_plan(plan=plan, known_input_keys=input_keys)
    return plan
