from __future__ import annotations

import logging
from typing import cast

from src.domain import do_template_plan_support
from src.domain import plan_contract as pc
from src.domain.do_template_catalog import DoTemplateCatalog
from src.domain.do_template_repository import DoTemplateRepository
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import Job, JobConfirmation, JobStatus, LLMPlan, PlanSource
from src.domain.plan_contract_extract import missing_required_template_params
from src.domain.plan_freeze_gate import (
    missing_draft_fields_for_plan_freeze,
    next_actions_for_plan_freeze_missing,
)
from src.domain.plan_generation_llm import PlanGenerationParseError
from src.domain.plan_id_support import build_plan_id, normalize_whitespace
from src.domain.plan_service_confirmation import effective_confirmation
from src.domain.plan_service_llm_builder import generate_plan_with_llm as build_llm_plan
from src.domain.plan_service_rule_builder import build_rule_plan
from src.domain.plan_service_support import ensure_plan_artifact_index, write_plan_artifact
from src.domain.plan_template_contract_builder import build_plan_template_contract
from src.infra.exceptions import LLMArtifactsWriteError, LLMCallFailedError
from src.infra.plan_exceptions import (
    PlanAlreadyFrozenError,
    PlanCompositionInvalidError,
    PlanFreezeMissingRequiredError,
    PlanFreezeNotAllowedError,
    PlanMissingError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)

_DEFAULT_PLAN_GENERATION_MAX_STEPS = 8
_LLM_FALLBACK_SSE_ERRORS = (PlanCompositionInvalidError, LLMCallFailedError, LLMArtifactsWriteError)


class PlanService:
    """Plan service: freeze a schema-bound plan and persist it as an artifact."""

    def __init__(
        self,
        *,
        store: JobStore,
        workspace: JobWorkspaceStore,
        do_template_catalog: DoTemplateCatalog,
        do_template_repo: DoTemplateRepository,
        llm: LLMClient | None = None,
        plan_generation_max_steps: int = _DEFAULT_PLAN_GENERATION_MAX_STEPS,
    ):
        self._store = store
        self._workspace = workspace
        self._do_template_catalog = do_template_catalog
        self._do_template_repo = do_template_repo
        self._llm = llm
        self._plan_generation_max_steps = int(plan_generation_max_steps)

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
        confirmation = effective_confirmation(job=job, confirmation=confirmation)
        job, confirmation = pc.apply_confirmation_effects(job=job, confirmation=confirmation)
        expected_plan_id = self._expected_plan_id(job=job, confirmation=confirmation)
        existing = self._return_existing_plan_if_idempotent(
            job=job, expected_plan_id=expected_plan_id
        )
        if existing is not None:
            return existing
        self._ensure_freeze_allowed(job=job)
        self._ensure_required_inputs_present(job=job, confirmation=confirmation)
        pc.validate_contract_columns(workspace=self._workspace, tenant_id=tenant_id, job=job)
        plan = self._build_plan_with_fallback(
            tenant_id=tenant_id, job=job, confirmation=confirmation, plan_id=expected_plan_id
        )
        write_plan_artifact(store=self._store, tenant_id=tenant_id, job_id=job_id, plan=plan)
        self._persist_frozen_plan(
            tenant_id=tenant_id, job=job, confirmation=confirmation, plan=plan
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
            draft=job.draft, answers=confirmation.answers
        )

        analysis_spec = pc.analysis_spec_from_draft(job=job)
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
            job_id=job.job_id, missing_fields=missing_fields, missing_params=missing_params
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

    def _build_rule_plan(self, *, job: Job, confirmation: JobConfirmation, plan_id: str) -> LLMPlan:
        analysis_spec = pc.analysis_spec_from_draft(job=job)
        analysis_vars = do_template_plan_support.analysis_vars_from_analysis_spec(analysis_spec)
        template_id = self._resolve_template_id(job=job, analysis_vars=analysis_vars)
        return build_rule_plan(
            job=job,
            confirmation=confirmation,
            plan_id=plan_id,
            template_id=template_id,
            workspace=self._workspace,
            do_template_repo=self._do_template_repo,
        )

    def generate_plan_with_llm(
        self,
        *,
        tenant_id: str,
        job: Job,
        confirmation: JobConfirmation,
        plan_id: str,
    ) -> LLMPlan:
        llm = self._llm
        if llm is None:
            raise ValueError("llm dependency missing")
        analysis_spec = pc.analysis_spec_from_draft(job=job)
        analysis_vars = do_template_plan_support.analysis_vars_from_analysis_spec(analysis_spec)
        primary_template_id = self._resolve_template_id(job=job, analysis_vars=analysis_vars)
        return build_llm_plan(
            tenant_id=tenant_id,
            job=job,
            confirmation=confirmation,
            plan_id=plan_id,
            llm=llm,
            workspace=self._workspace,
            do_template_repo=self._do_template_repo,
            primary_template_id=primary_template_id,
            max_steps=self._plan_generation_max_steps,
        )

    def _build_plan_with_fallback(
        self,
        *,
        tenant_id: str,
        job: Job,
        confirmation: JobConfirmation,
        plan_id: str,
    ) -> LLMPlan:
        if self._llm is None:
            return self._build_rule_plan(job=job, confirmation=confirmation, plan_id=plan_id)
        try:
            return self.generate_plan_with_llm(
                tenant_id=tenant_id, job=job, confirmation=confirmation, plan_id=plan_id
            )
        except (
            PlanGenerationParseError,
            PlanCompositionInvalidError,
            LLMCallFailedError,
            LLMArtifactsWriteError,
            ValueError,
        ) as e:
            reason = f"{type(e).__name__}:{e}"
            if isinstance(e, PlanGenerationParseError):
                reason = f"{e.error_code}:{e}"
            elif isinstance(e, _LLM_FALLBACK_SSE_ERRORS):
                reason = f"{e.error_code}:{e.message}"
            logger.warning(
                "SS_PLAN_LLM_FALLBACK",
                extra={
                    "job_id": job.job_id,
                    "fallback_reason": reason,
                    "error_type": type(e).__name__,
                },
            )
            plan = self._build_rule_plan(job=job, confirmation=confirmation, plan_id=plan_id)
            return plan.model_copy(
                update={
                    "plan_source": PlanSource.RULE_FALLBACK,
                    "fallback_reason": reason,
                }
            )
