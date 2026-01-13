from __future__ import annotations

from src.domain.do_template_catalog import DoTemplateCatalog, TemplateSummary
from src.domain.do_template_selection_models import (
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.domain.do_template_selection_prompting import rank_templates, trim_templates
from src.infra.do_template_selection_exceptions import DoTemplateSelectionNoCandidatesError


def stage1_context(
    *, stage1: Stage1FamilySelection | Stage1FamilySelectionV2
) -> tuple[tuple[str, ...], bool, str]:
    if isinstance(stage1, Stage1FamilySelectionV2):
        sequence = tuple(item.strip() for item in stage1.analysis_sequence if item.strip() != "")
        return sequence, bool(stage1.requires_combination), stage1.combination_reason
    return tuple(), False, ""


def primary_confidence(*, stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2) -> float:
    if isinstance(stage2, Stage2TemplateSelectionV2):
        return float(stage2.primary_confidence)
    return float(stage2.confidence)


def stage2_primary_template_id(
    *, stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2
) -> str:
    if isinstance(stage2, Stage2TemplateSelectionV2):
        return stage2.primary_template_id
    return stage2.template_id


def build_stage2_candidates(
    *,
    catalog: DoTemplateCatalog,
    selected_family_ids: tuple[str, ...],
    requirement: str,
    token_budget: int,
    max_candidates: int,
    supported_template_ids: frozenset[str],
) -> tuple[TemplateSummary, ...]:
    templates = catalog.list_templates(family_ids=selected_family_ids)
    if not templates:
        raise DoTemplateSelectionNoCandidatesError(stage="stage2_templates")

    filtered = tuple(t for t in templates if t.template_id in supported_template_ids)
    templates_for_ranking = filtered if filtered else templates
    ranked = rank_templates(requirement=requirement, templates=templates_for_ranking)
    candidates = trim_templates(
        templates=ranked,
        token_budget=int(token_budget),
        max_candidates=int(max_candidates),
    )
    if not candidates:
        raise DoTemplateSelectionNoCandidatesError(stage="stage2_candidates")
    return candidates


def manual_fallback_template_id(*, candidates: tuple[TemplateSummary, ...]) -> str:
    if candidates:
        return candidates[0].template_id
    raise DoTemplateSelectionNoCandidatesError(stage="stage2_manual_fallback")


def finalize_stage2_selection(
    *,
    stage2: Stage2TemplateSelection | Stage2TemplateSelectionV2,
    llm_primary_template_id: str,
    llm_supplementary_template_ids: tuple[str, ...],
    candidates: tuple[TemplateSummary, ...],
    confirmation_threshold: float,
    manual_fallback_threshold: float,
) -> tuple[str, tuple[str, ...], float, bool, bool]:
    confidence = primary_confidence(stage2=stage2)
    requires_user_confirmation = confidence < float(confirmation_threshold)
    used_manual_fallback = confidence < float(manual_fallback_threshold)
    selected_template_id = llm_primary_template_id
    supplementary = llm_supplementary_template_ids
    if used_manual_fallback:
        selected_template_id = manual_fallback_template_id(candidates=candidates)
        supplementary = tuple()
    return (
        selected_template_id,
        supplementary,
        confidence,
        requires_user_confirmation,
        used_manual_fallback,
    )
