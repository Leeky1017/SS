from __future__ import annotations

import logging
from typing import cast

from src.domain import do_template_plan_support
from src.domain.composition_plan import validate_composition_plan
from src.domain.do_template_catalog import DoTemplateCatalog
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import (
    Job,
    JobConfirmation,
    JobStatus,
    LLMPlan,
)
from src.domain.plan_contract import (
    analysis_spec_from_draft,
    apply_confirmation_effects,
    validate_contract_columns,
)
from src.domain.plan_contract_extract import missing_required_template_params
from src.domain.plan_freeze_gate import (
    missing_draft_fields_for_plan_freeze,
    next_actions_for_plan_freeze_missing,
)
from src.domain.plan_id_support import build_plan_id, normalize_whitespace, sha256_hex
from src.domain.plan_routing import choose_composition_mode
from src.domain.plan_service_support import (
    ensure_plan_artifact_index,
    known_input_keys,
    write_plan_artifact,
)
from src.domain.plan_steps import build_plan_steps
from src.domain.plan_template_contract_builder import build_plan_template_contract
from src.infra.plan_exceptions import (
    PlanAlreadyFrozenError,
    PlanFreezeMissingRequiredError,
    PlanFreezeNotAllowedError,
    PlanMissingError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class PlanService:
    """Plan service: freeze a schema-bound plan and persist it as an artifact."""

    def __init__(
        self,
        *,
        store: JobStore,
        workspace: JobWorkspaceStore,
        do_template_catalog: DoTemplateCatalog,
        do_template_repo: DoTemplateRepository,
    ):
        self._store = store
        self._workspace = workspace
        self._do_template_catalog = do_template_catalog
        self._do_template_repo = do_template_repo

    def _return_existing_plan_if_idempotent(
        self, *, job: Job, expected_plan_id: str
    ) -> LLMPlan | None:
        existing = job.llm_plan
        if existing is None:
            return None
        if existing.plan_id != expected_plan_id:
            logger.warning(
                "SS_PLAN_ALREADY_FROZEN_CONFLICT",
                extra={
                    "job_id": job.job_id,
                    "existing_plan_id": existing.plan_id,
                    "expected_plan_id": expected_plan_id,
                },
            )
            raise PlanAlreadyFrozenError(job_id=job.job_id)
        logger.info(
            "SS_PLAN_FREEZE_IDEMPOTENT",
            extra={"job_id": job.job_id, "plan_id": existing.plan_id},
        )
        return existing

    def _ensure_freeze_allowed(self, *, job: Job) -> None:
        if job.status in {JobStatus.DRAFT_READY, JobStatus.CONFIRMED}:
            return
        logger.warning(
            "SS_PLAN_FREEZE_NOT_ALLOWED",
            extra={"job_id": job.job_id, "status": job.status.value},
        )
        raise PlanFreezeNotAllowedError(job_id=job.job_id, status=job.status.value)

    def _persist_frozen_plan(
        self, *, tenant_id: str, job: Job, confirmation: JobConfirmation, plan: LLMPlan
    ) -> None:
        job.confirmation = confirmation
        job.llm_plan = plan
        ensure_plan_artifact_index(job=job, rel_path=plan.rel_path)
        self._store.save(tenant_id=tenant_id, job=job)

    def freeze_plan(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        confirmation: JobConfirmation,
    ) -> LLMPlan:
        logger.info("SS_PLAN_FREEZE_START", extra={"tenant_id": tenant_id, "job_id": job_id})
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        confirmation = self._effective_confirmation(job=job, confirmation=confirmation)
        job, confirmation = apply_confirmation_effects(job=job, confirmation=confirmation)
        expected_plan_id = self._expected_plan_id(job=job, confirmation=confirmation)

        existing = self._return_existing_plan_if_idempotent(
            job=job,
            expected_plan_id=expected_plan_id,
        )
        if existing is not None:
            return existing
        self._ensure_freeze_allowed(job=job)

        self._ensure_required_inputs_present(job=job, confirmation=confirmation)
        validate_contract_columns(workspace=self._workspace, tenant_id=tenant_id, job=job)
        plan = self._build_plan(job=job, confirmation=confirmation, plan_id=expected_plan_id)
        write_plan_artifact(store=self._store, tenant_id=tenant_id, job_id=job_id, plan=plan)

        self._persist_frozen_plan(
            tenant_id=tenant_id,
            job=job,
            confirmation=confirmation,
            plan=plan,
        )
        logger.info(
            "SS_PLAN_FROZEN",
            extra={"tenant_id": tenant_id, "job_id": job_id, "plan_id": plan.plan_id},
        )
        return plan

    def get_frozen_plan(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
    ) -> LLMPlan:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.llm_plan is None:
            raise PlanMissingError(job_id=job_id)
        return job.llm_plan

    def _effective_confirmation(
        self,
        *,
        job: Job,
        confirmation: JobConfirmation,
    ) -> JobConfirmation:
        updates: dict[str, object] = {}
        if confirmation.requirement is None:
            updates["requirement"] = job.requirement
        existing = job.confirmation
        if existing is not None:
            missing_corrections = len(confirmation.variable_corrections) == 0
            existing_corrections = len(existing.variable_corrections) > 0
            if missing_corrections and existing_corrections:
                updates["variable_corrections"] = existing.variable_corrections

            missing_overrides = len(confirmation.default_overrides) == 0
            existing_overrides = len(existing.default_overrides) > 0
            if missing_overrides and existing_overrides:
                updates["default_overrides"] = existing.default_overrides
        if len(updates) == 0:
            return confirmation
        return confirmation.model_copy(update=updates)

    def _expected_plan_id(self, *, job: Job, confirmation: JobConfirmation) -> str:
        inputs_fingerprint = ""
        if job.inputs is not None and job.inputs.fingerprint is not None:
            inputs_fingerprint = job.inputs.fingerprint

        requirement = job.requirement if job.requirement is not None else ""
        requirement_norm = normalize_whitespace(requirement)
        confirmation_payload = cast(JsonObject, confirmation.model_dump(mode="json"))
        return build_plan_id(
            job_id=job.job_id,
            inputs_fingerprint=inputs_fingerprint,
            requirement=requirement_norm,
            confirmation=confirmation_payload,
        )

    def _ensure_required_inputs_present(self, *, job: Job, confirmation: JobConfirmation) -> None:
        missing_fields = missing_draft_fields_for_plan_freeze(
            draft=job.draft,
            answers=confirmation.answers,
        )

        analysis_spec = analysis_spec_from_draft(job=job)
        analysis_vars = do_template_plan_support.analysis_vars_from_analysis_spec(analysis_spec)
        template_id = self._resolve_template_id(job=job, analysis_vars=analysis_vars)
        template_params = do_template_plan_support.template_params_for(
            template_id=template_id, analysis_vars=analysis_vars
        )
        template_contract = build_plan_template_contract(
            repo=self._do_template_repo,
            job_id=job.job_id,
            template_id=template_id,
            template_params=template_params,
        )
        missing_params = missing_required_template_params(template_contract=template_contract)

        if len(missing_fields) == 0 and len(missing_params) == 0:
            return

        next_actions = next_actions_for_plan_freeze_missing(
            job_id=job.job_id,
            missing_fields=missing_fields,
            missing_params=missing_params,
        )
        logger.info(
            "SS_PLAN_FREEZE_MISSING_REQUIRED",
            extra={
                "job_id": job.job_id,
                "template_id": template_id,
                "missing_fields": ",".join(missing_fields),
                "missing_params": ",".join(missing_params),
            },
        )
        raise PlanFreezeMissingRequiredError(
            job_id=job.job_id,
            template_id=template_id,
            missing_fields=missing_fields,
            missing_params=missing_params,
            next_actions=next_actions,
        )

    def _resolve_template_id(self, *, job: Job, analysis_vars: list[str]) -> str:
        template_id = job.selected_template_id
        if template_id is not None and template_id.strip() != "":
            return template_id
        selected = do_template_plan_support.select_template_id(
            catalog=self._do_template_catalog,
            repo=self._do_template_repo,
            analysis_vars=analysis_vars,
        )
        logger.info(
            "SS_PLAN_TEMPLATE_SELECTED_FALLBACK",
            extra={"job_id": job.job_id, "template_id": selected},
        )
        job.selected_template_id = selected
        return selected

    def _build_plan(self, *, job: Job, confirmation: JobConfirmation, plan_id: str) -> LLMPlan:
        requirement = confirmation.requirement if confirmation.requirement is not None else ""
        requirement_norm = normalize_whitespace(requirement)
        requirement_fingerprint = sha256_hex(requirement_norm)
        analysis_spec = analysis_spec_from_draft(job=job)
        analysis_vars = do_template_plan_support.analysis_vars_from_analysis_spec(analysis_spec)
        template_id = self._resolve_template_id(job=job, analysis_vars=analysis_vars)
        template_params = do_template_plan_support.template_params_for(
            template_id=template_id, analysis_vars=analysis_vars
        )
        contract = build_plan_template_contract(
            repo=self._do_template_repo,
            job_id=job.job_id,
            template_id=template_id,
            template_params=template_params,
        )
        input_keys = known_input_keys(workspace=self._workspace, job=job)
        primary_key = "primary" if "primary" in input_keys else sorted(input_keys)[0]
        composition_mode = choose_composition_mode(
            requirement=requirement_norm,
            input_keys=input_keys,
        )
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
