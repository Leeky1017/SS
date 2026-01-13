from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Callable

from src.domain.do_template_catalog import DoTemplateCatalog, FamilySummary, TemplateSummary
from src.domain.do_template_selection_evidence_writer import (
    finalize_selection_for_job,
    persist_best_effort,
)
from src.domain.do_template_selection_models import (
    DoTemplateSelectionResult,
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.domain.do_template_selection_prompting import (
    parse_stage1,
    parse_stage2,
    stage1_prompt,
    stage2_prompt,
)
from src.domain.do_template_selection_service_support import (
    build_stage2_candidates,
    stage1_context,
    stage2_primary_template_id,
)
from src.domain.do_template_selection_validation import (
    validated_family_ids,
    validated_template_selection,
)
from src.domain.job_store import JobStore
from src.domain.llm_client import LLMClient
from src.domain.models import Job
from src.infra.do_template_selection_exceptions import (
    DoTemplateSelectionInvalidFamilyIdError,
    DoTemplateSelectionInvalidTemplateIdError,
    DoTemplateSelectionNoCandidatesError,
)
from src.infra.exceptions import SSError
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

_V1_SUPPORTED_TEMPLATE_IDS = frozenset({"T01", "T05", "T07", "T09", "T30", "TA14"})
_STAGE2_OP = "do_template.select_template"


@dataclass(frozen=True)
class DoTemplateSelectionService:
    store: JobStore
    llm: LLMClient
    catalog: DoTemplateCatalog
    stage1_max_families: int = 3
    stage2_max_candidates: int = 30
    stage2_token_budget: int = 2000
    confirmation_threshold: float = 0.6
    manual_fallback_threshold: float = 0.3
    max_attempts: int = 2
    clock: Callable[[], datetime] = utc_now

    async def select_template_id(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
    ) -> DoTemplateSelectionResult:
        logger.info("SS_DO_TEMPLATE_SELECT_START", extra={"tenant_id": tenant_id, "job_id": job_id})
        job = self.store.load(tenant_id=tenant_id, job_id=job_id)
        existing_template_id = job.selected_template_id
        if isinstance(existing_template_id, str) and existing_template_id.strip() != "":
            logger.info(
                "SS_DO_TEMPLATE_SELECT_IDEMPOTENT",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "template_id": existing_template_id,
                },
            )
            return DoTemplateSelectionResult(
                selected_family_ids=tuple(),
                candidate_template_ids=tuple(),
                selected_template_id=existing_template_id,
            )
        try:
            result = await self._select_for_job(job=job)
        except SSError as e:
            persist_best_effort(store=self.store, tenant_id=tenant_id, job=job, error=e)
            raise
        self.store.save(tenant_id=tenant_id, job=job)
        logger.info(
            "SS_DO_TEMPLATE_SELECT_DONE",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "template_id": result.selected_template_id,
            },
        )
        return result

    def _v1_families_for_prompt(
        self, *, families: tuple[FamilySummary, ...]
    ) -> tuple[FamilySummary, ...]:
        eligible = tuple(
            family
            for family in families
            if any(tid in _V1_SUPPORTED_TEMPLATE_IDS for tid in family.template_ids)
        )
        return eligible if eligible else families

    async def _select_for_job(self, *, job: Job) -> DoTemplateSelectionResult:
        requirement = job.requirement if job.requirement is not None else ""
        families = self.catalog.list_families()
        if not families:
            raise DoTemplateSelectionNoCandidatesError(stage="stage1")

        families_for_prompt = self._v1_families_for_prompt(families=families)
        stage1, selected_family_ids = await self._select_families(
            job=job, requirement=requirement, families=families_for_prompt
        )
        analysis_sequence, requires_combination, combination_reason = stage1_context(stage1=stage1)
        candidates = build_stage2_candidates(
            catalog=self.catalog,
            selected_family_ids=selected_family_ids,
            requirement=requirement,
            token_budget=int(self.stage2_token_budget),
            max_candidates=int(self.stage2_max_candidates),
            supported_template_ids=_V1_SUPPORTED_TEMPLATE_IDS,
        )

        stage2, llm_primary_id, llm_supplementary_ids = await self._select_template(
            job=job,
            requirement=requirement,
            selected_family_ids=selected_family_ids,
            analysis_sequence=analysis_sequence,
            requires_combination=requires_combination,
            combination_reason=combination_reason,
            candidates=candidates,
        )
        return finalize_selection_for_job(
            store=self.store,
            job=job,
            requirement=requirement,
            families=families,
            stage1=stage1,
            selected_family_ids=selected_family_ids,
            candidates=candidates,
            stage2=stage2,
            llm_primary_template_id=llm_primary_id,
            llm_supplementary_template_ids=llm_supplementary_ids,
            analysis_sequence=analysis_sequence,
            requires_combination=requires_combination,
            confirmation_threshold=float(self.confirmation_threshold),
            manual_fallback_threshold=float(self.manual_fallback_threshold),
            stage1_max_families=int(self.stage1_max_families),
            stage2_token_budget=int(self.stage2_token_budget),
            stage2_max_candidates=int(self.stage2_max_candidates),
        )

    async def _select_families(
        self,
        *,
        job: Job,
        requirement: str,
        families: tuple[FamilySummary, ...],
    ) -> tuple[Stage1FamilySelection | Stage1FamilySelectionV2, tuple[str, ...]]:
        canonical = frozenset(f.family_id for f in families)
        previous_error = None
        last: Stage1FamilySelection | Stage1FamilySelectionV2 | None = None
        for attempt in range(1, max(1, int(self.max_attempts)) + 1):
            prompt = stage1_prompt(
                requirement=requirement,
                families=families,
                max_families=int(self.stage1_max_families),
                attempt=attempt,
                previous_error=previous_error,
            )
            text = await self.llm.complete_text(
                job=job, operation="do_template.select_families", prompt=prompt
            )
            parsed = parse_stage1(text)
            last = parsed
            try:
                ids = validated_family_ids(
                    selection=parsed,
                    canonical_family_ids=canonical,
                    max_families=int(self.stage1_max_families),
                )
            except DoTemplateSelectionInvalidFamilyIdError as e:
                previous_error = f"{e.error_code}:{e.message}"
                continue
            if ids:
                logger.info(
                    "SS_DO_TEMPLATE_SELECT_STAGE1_OK",
                    extra={"job_id": job.job_id, "n_selected": len(ids)},
                )
                return parsed, ids
            previous_error = "empty_selection"
        if last is not None:
            raise DoTemplateSelectionNoCandidatesError(stage="stage1_invalid_or_empty")
        raise DoTemplateSelectionNoCandidatesError(stage="stage1")

    async def _select_template(
        self,
        *,
        job: Job,
        requirement: str,
        selected_family_ids: tuple[str, ...],
        analysis_sequence: tuple[str, ...],
        requires_combination: bool,
        combination_reason: str,
        candidates: tuple[TemplateSummary, ...],
    ) -> tuple[Stage2TemplateSelection | Stage2TemplateSelectionV2, str, tuple[str, ...]]:
        candidate_ids = frozenset(t.template_id for t in candidates)
        previous_error = None
        last: Stage2TemplateSelection | Stage2TemplateSelectionV2 | None = None
        for attempt in range(1, max(1, int(self.max_attempts)) + 1):
            prompt = stage2_prompt(
                requirement=requirement, selected_family_ids=selected_family_ids,
                analysis_sequence=analysis_sequence, requires_combination=requires_combination,
                combination_reason=combination_reason, candidates=candidates,
                token_budget=int(self.stage2_token_budget), attempt=attempt,
                previous_error=previous_error,
            )
            text = await self.llm.complete_text(job=job, operation=_STAGE2_OP, prompt=prompt)
            parsed = parse_stage2(text)
            last = parsed
            try:
                primary_template_id, supplementary_template_ids = validated_template_selection(
                    selection=parsed,
                    candidate_template_ids=candidate_ids,
                )
            except DoTemplateSelectionInvalidTemplateIdError as e:
                previous_error = f"{e.error_code}:{e.message}"
                continue
            logger.info(
                "SS_DO_TEMPLATE_SELECT_STAGE2_OK",
                extra={
                    "job_id": job.job_id,
                    "template_id": primary_template_id,
                    "n_supplementary": len(supplementary_template_ids),
                    "n_candidates": len(candidate_ids),
                },
            )
            return parsed, primary_template_id, supplementary_template_ids
        if last is not None:
            bad_template_id = stage2_primary_template_id(stage2=last)
            raise DoTemplateSelectionInvalidTemplateIdError(template_id=bad_template_id)
        raise DoTemplateSelectionNoCandidatesError(stage="stage2")
