from __future__ import annotations

import logging
from dataclasses import dataclass
from datetime import datetime
from typing import Callable

from src.domain.do_template_catalog import DoTemplateCatalog, FamilySummary, TemplateSummary
from src.domain.do_template_selection_models import (
    DoTemplateSelectionResult,
    Stage1FamilySelection,
    Stage2TemplateSelection,
)
from src.domain.do_template_selection_prompting import (
    candidates_evidence_payload,
    parse_stage1,
    parse_stage2,
    rank_templates,
    selection_artifact_paths,
    stage1_evidence_payload,
    stage1_prompt,
    stage2_evidence_payload,
    stage2_prompt,
    trim_templates,
)
from src.domain.do_template_selection_validation import (
    validated_family_ids,
    validated_template_id,
)
from src.domain.job_store import JobStore
from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, ArtifactRef, Job
from src.infra.do_template_selection_exceptions import (
    DoTemplateSelectionInvalidFamilyIdError,
    DoTemplateSelectionInvalidTemplateIdError,
    DoTemplateSelectionNoCandidatesError,
)
from src.infra.exceptions import JobStoreIOError, SSError
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class DoTemplateSelectionService:
    store: JobStore
    llm: LLMClient
    catalog: DoTemplateCatalog
    stage1_max_families: int = 3
    stage2_max_candidates: int = 30
    stage2_token_budget: int = 2000
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
        try:
            result = await self._select_for_job(job=job)
        except SSError as e:
            self._persist_best_effort(tenant_id=tenant_id, job=job, error=e)
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

    async def _select_for_job(self, *, job: Job) -> DoTemplateSelectionResult:
        requirement = job.requirement if job.requirement is not None else ""
        families = self.catalog.list_families()
        if not families:
            raise DoTemplateSelectionNoCandidatesError(stage="stage1")

        stage1, selected_family_ids = await self._select_families(
            job=job, requirement=requirement, families=families
        )

        templates = self.catalog.list_templates(family_ids=selected_family_ids)
        if not templates:
            raise DoTemplateSelectionNoCandidatesError(stage="stage2_templates")

        ranked = rank_templates(requirement=requirement, templates=templates)
        candidates = trim_templates(
            templates=ranked,
            token_budget=int(self.stage2_token_budget),
            max_candidates=int(self.stage2_max_candidates),
        )
        if not candidates:
            raise DoTemplateSelectionNoCandidatesError(stage="stage2_candidates")

        stage2, template_id = await self._select_template(
            job=job,
            requirement=requirement,
            selected_family_ids=selected_family_ids,
            candidates=candidates,
        )
        self._write_evidence(
            job=job,
            requirement=requirement,
            families=families,
            stage1=stage1,
            selected_family_ids=selected_family_ids,
            candidates=candidates,
            stage2=stage2,
            selected_template_id=template_id,
        )
        return DoTemplateSelectionResult(
            selected_family_ids=selected_family_ids,
            candidate_template_ids=tuple(t.template_id for t in candidates),
            selected_template_id=template_id,
        )

    async def _select_families(
        self,
        *,
        job: Job,
        requirement: str,
        families: tuple[FamilySummary, ...],
    ) -> tuple[Stage1FamilySelection, tuple[str, ...]]:
        canonical = frozenset(f.family_id for f in families)
        previous_error = None
        last: Stage1FamilySelection | None = None
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
        candidates: tuple[TemplateSummary, ...],
    ) -> tuple[Stage2TemplateSelection, str]:
        candidate_ids = frozenset(t.template_id for t in candidates)
        previous_error = None
        last: Stage2TemplateSelection | None = None
        for attempt in range(1, max(1, int(self.max_attempts)) + 1):
            prompt = stage2_prompt(
                requirement=requirement,
                selected_family_ids=selected_family_ids,
                candidates=candidates,
                token_budget=int(self.stage2_token_budget),
                attempt=attempt,
                previous_error=previous_error,
            )
            text = await self.llm.complete_text(
                job=job, operation="do_template.select_template", prompt=prompt
            )
            parsed = parse_stage2(text)
            last = parsed
            try:
                template_id = validated_template_id(
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
                    "template_id": template_id,
                    "n_candidates": len(candidate_ids),
                },
            )
            return parsed, template_id
        if last is not None:
            raise DoTemplateSelectionInvalidTemplateIdError(template_id=last.template_id)
        raise DoTemplateSelectionNoCandidatesError(stage="stage2")

    def _write_evidence(
        self,
        *,
        job: Job,
        requirement: str,
        families: tuple[FamilySummary, ...],
        stage1: Stage1FamilySelection,
        selected_family_ids: tuple[str, ...],
        candidates: tuple[TemplateSummary, ...],
        stage2: Stage2TemplateSelection,
        selected_template_id: str,
    ) -> None:
        stage1_rel, candidates_rel, stage2_rel = selection_artifact_paths()
        self._write_artifact(
            job=job,
            kind=ArtifactKind.DO_TEMPLATE_SELECTION_STAGE1,
            rel_path=stage1_rel,
            payload=stage1_evidence_payload(
                job_id=job.job_id,
                requirement=requirement,
                families=families,
                stage1=stage1,
                selected_family_ids=selected_family_ids,
                max_families=int(self.stage1_max_families),
            ),
        )
        self._write_artifact(
            job=job,
            kind=ArtifactKind.DO_TEMPLATE_SELECTION_CANDIDATES,
            rel_path=candidates_rel,
            payload=candidates_evidence_payload(
                job_id=job.job_id,
                selected_family_ids=selected_family_ids,
                candidates=candidates,
                token_budget=int(self.stage2_token_budget),
                max_candidates=int(self.stage2_max_candidates),
            ),
        )
        self._write_artifact(
            job=job,
            kind=ArtifactKind.DO_TEMPLATE_SELECTION_STAGE2,
            rel_path=stage2_rel,
            payload=stage2_evidence_payload(
                job_id=job.job_id,
                requirement=requirement,
                candidates=candidates,
                stage2=stage2,
                selected_template_id=selected_template_id,
            ),
        )

    def _write_artifact(
        self,
        *,
        job: Job,
        kind: ArtifactKind,
        rel_path: str,
        payload: dict[str, object],
    ) -> None:
        self.store.write_artifact_json(
            tenant_id=job.tenant_id,
            job_id=job.job_id,
            rel_path=rel_path,
            payload=payload,
        )
        self._append_artifact_ref(job=job, kind=kind, rel_path=rel_path)

    def _append_artifact_ref(self, *, job: Job, kind: ArtifactKind, rel_path: str) -> None:
        if any(ref.kind == kind and ref.rel_path == rel_path for ref in job.artifacts_index):
            return
        job.artifacts_index.append(ArtifactRef(kind=kind, rel_path=rel_path))

    def _persist_best_effort(self, *, tenant_id: str, job: Job, error: SSError) -> None:
        logger.warning(
            "SS_DO_TEMPLATE_SELECT_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job.job_id,
                "error_code": error.error_code,
                "error_message": error.message,
            },
        )
        try:
            self.store.save(tenant_id=tenant_id, job=job)
        except JobStoreIOError as persist_error:
            logger.warning(
                "SS_DO_TEMPLATE_SELECT_PERSIST_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "error_code": persist_error.error_code,
                    "error_message": persist_error.message,
                },
            )
