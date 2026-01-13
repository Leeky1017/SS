from __future__ import annotations

import logging

from src.domain.do_template_catalog import FamilySummary, TemplateSummary
from src.domain.do_template_selection_evidence_payloads import (
    candidates_evidence_payload,
    selection_artifact_paths,
    stage1_evidence_payload,
    stage2_evidence_payload,
)
from src.domain.do_template_selection_models import (
    DoTemplateSelectionResult,
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.domain.do_template_selection_service_support import finalize_stage2_selection
from src.domain.job_store import JobStore
from src.domain.models import ArtifactKind, ArtifactRef, Job
from src.infra.exceptions import JobStoreIOError, SSError
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def _log_low_confidence(
    *,
    job_id: str,
    primary_confidence: float,
    selected_template_id: str,
    used_manual_fallback: bool,
) -> None:
    logger.warning(
        "SS_DO_TEMPLATE_SELECT_LOW_CONFIDENCE",
        extra={
            "job_id": job_id,
            "primary_confidence": primary_confidence,
            "selected_template_id": selected_template_id,
            "used_manual_fallback": used_manual_fallback,
        },
    )


def write_selection_evidence(
    *,
    store: JobStore,
    job: Job,
    requirement: str,
    families: tuple[FamilySummary, ...],
    stage1: Stage1FamilySelection | Stage1FamilySelectionV2,
    selected_family_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2,
    result: DoTemplateSelectionResult,
    stage1_max_families: int,
    stage2_token_budget: int,
    stage2_max_candidates: int,
) -> None:
    job_id = job.job_id
    stage1_rel, candidates_rel, stage2_rel = selection_artifact_paths()
    stage1_payload = stage1_evidence_payload(
        job_id=job_id, requirement=requirement, families=families, stage1=stage1,
        selected_family_ids=selected_family_ids, max_families=int(stage1_max_families),
    )
    candidates_payload = candidates_evidence_payload(
        job_id=job_id, selected_family_ids=selected_family_ids, candidates=candidates,
        token_budget=int(stage2_token_budget), max_candidates=int(stage2_max_candidates),
    )
    stage2_payload = stage2_evidence_payload(
        job_id=job_id,
        requirement=requirement,
        candidates=candidates,
        stage2=stage2,
        selected_template_id=result.selected_template_id,
        supplementary_template_ids=result.supplementary_template_ids,
        primary_confidence=result.primary_confidence,
        requires_user_confirmation=result.requires_user_confirmation,
        used_manual_fallback=result.used_manual_fallback,
    )
    for kind, rel_path, payload in (
        (ArtifactKind.DO_TEMPLATE_SELECTION_STAGE1, stage1_rel, stage1_payload),
        (ArtifactKind.DO_TEMPLATE_SELECTION_CANDIDATES, candidates_rel, candidates_payload),
        (ArtifactKind.DO_TEMPLATE_SELECTION_STAGE2, stage2_rel, stage2_payload),
    ):
        _write_artifact(store=store, job=job, kind=kind, rel_path=rel_path, payload=payload)


def _build_result(
    *,
    selected_family_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    selected_template_id: str,
    supplementary_ids: tuple[str, ...],
    analysis_sequence: tuple[str, ...],
    requires_combination: bool,
    needs_confirm: bool,
    used_manual_fallback: bool,
    primary_confidence: float,
) -> DoTemplateSelectionResult:
    return DoTemplateSelectionResult(
        selected_family_ids=selected_family_ids,
        candidate_template_ids=tuple(t.template_id for t in candidates),
        selected_template_id=selected_template_id,
        supplementary_template_ids=supplementary_ids,
        analysis_sequence=analysis_sequence,
        requires_combination=requires_combination,
        requires_user_confirmation=needs_confirm,
        used_manual_fallback=used_manual_fallback,
        primary_confidence=primary_confidence,
    )


def finalize_selection_for_job(
    *,
    store: JobStore,
    job: Job,
    requirement: str,
    families: tuple[FamilySummary, ...],
    stage1: Stage1FamilySelection | Stage1FamilySelectionV2,
    selected_family_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2,
    llm_primary_template_id: str,
    llm_supplementary_template_ids: tuple[str, ...],
    analysis_sequence: tuple[str, ...],
    requires_combination: bool,
    confirmation_threshold: float,
    manual_fallback_threshold: float,
    stage1_max_families: int,
    stage2_token_budget: int,
    stage2_max_candidates: int,
) -> DoTemplateSelectionResult:
    (
        selected_template_id,
        supplementary_ids,
        primary_confidence,
        needs_confirm,
        used_manual_fallback,
    ) = finalize_stage2_selection(
        stage2=stage2,
        llm_primary_template_id=llm_primary_template_id,
        llm_supplementary_template_ids=llm_supplementary_template_ids,
        candidates=candidates,
        confirmation_threshold=float(confirmation_threshold),
        manual_fallback_threshold=float(manual_fallback_threshold),
    )
    if needs_confirm:
        _log_low_confidence(
            job_id=job.job_id,
            primary_confidence=primary_confidence,
            selected_template_id=selected_template_id,
            used_manual_fallback=used_manual_fallback,
        )
    result = _build_result(
        selected_family_ids=selected_family_ids,
        candidates=candidates,
        selected_template_id=selected_template_id,
        supplementary_ids=supplementary_ids,
        analysis_sequence=analysis_sequence,
        requires_combination=requires_combination,
        needs_confirm=needs_confirm,
        used_manual_fallback=used_manual_fallback,
        primary_confidence=primary_confidence,
    )
    write_selection_evidence(
        store=store,
        job=job,
        requirement=requirement,
        families=families,
        stage1=stage1,
        selected_family_ids=selected_family_ids,
        candidates=candidates,
        stage2=stage2,
        result=result,
        stage1_max_families=int(stage1_max_families),
        stage2_token_budget=int(stage2_token_budget),
        stage2_max_candidates=int(stage2_max_candidates),
    )
    job.selected_template_id = result.selected_template_id
    return result


def _write_artifact(
    *,
    store: JobStore,
    job: Job,
    kind: ArtifactKind,
    rel_path: str,
    payload: JsonObject,
) -> None:
    store.write_artifact_json(
        tenant_id=job.tenant_id,
        job_id=job.job_id,
        rel_path=rel_path,
        payload=payload,
    )
    _append_artifact_ref(job=job, kind=kind, rel_path=rel_path)


def _append_artifact_ref(*, job: Job, kind: ArtifactKind, rel_path: str) -> None:
    if any(ref.kind == kind and ref.rel_path == rel_path for ref in job.artifacts_index):
        return
    job.artifacts_index.append(ArtifactRef(kind=kind, rel_path=rel_path))


def persist_best_effort(*, store: JobStore, tenant_id: str, job: Job, error: SSError) -> None:
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
        store.save(tenant_id=tenant_id, job=job)
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
