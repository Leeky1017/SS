from __future__ import annotations

from src.domain import do_template_plan_support
from src.domain.composition_plan import validate_composition_plan
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import Job, JobConfirmation, LLMPlan
from src.domain.plan_contract import analysis_spec_from_draft
from src.domain.plan_id_support import normalize_whitespace, sha256_hex
from src.domain.plan_routing import choose_composition_mode
from src.domain.plan_service_support import known_input_keys
from src.domain.plan_steps import build_plan_steps
from src.domain.plan_template_contract_builder import build_plan_template_contract


def build_rule_plan(
    *,
    job: Job,
    confirmation: JobConfirmation,
    plan_id: str,
    template_id: str,
    workspace: JobWorkspaceStore,
    do_template_repo: DoTemplateRepository,
) -> LLMPlan:
    requirement = "" if confirmation.requirement is None else confirmation.requirement
    requirement_norm = normalize_whitespace(requirement)
    requirement_fingerprint = sha256_hex(requirement_norm)
    analysis_spec = analysis_spec_from_draft(job=job)
    template_params = do_template_plan_support.template_params_for(
        template_id=template_id,
        analysis_spec=analysis_spec,
        variable_corrections=confirmation.variable_corrections,
    )
    contract = build_plan_template_contract(
        repo=do_template_repo,
        job_id=job.job_id,
        template_id=template_id,
        template_params=template_params,
    )
    input_keys = known_input_keys(workspace=workspace, job=job)
    primary_key = "primary" if "primary" in input_keys else sorted(input_keys)[0]
    composition_mode = choose_composition_mode(requirement=requirement_norm, input_keys=input_keys)
    steps = build_plan_steps(
        composition_mode=composition_mode.value,
        template_id=template_id,
        template_params=template_params,
        template_contract=contract,
        primary_key=primary_key,
        requirement_fingerprint=requirement_fingerprint,
        analysis_spec=analysis_spec,
    )
    plan = LLMPlan(plan_id=plan_id, rel_path="artifacts/plan.json", steps=steps)
    validate_composition_plan(plan=plan, known_input_keys=input_keys)
    return plan
