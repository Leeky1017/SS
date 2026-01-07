from __future__ import annotations

from src.domain.do_template_selection_models import Stage1FamilySelection, Stage2TemplateSelection
from src.infra.do_template_selection_exceptions import (
    DoTemplateSelectionInvalidFamilyIdError,
    DoTemplateSelectionInvalidTemplateIdError,
)


def validated_family_ids(
    *,
    selection: Stage1FamilySelection,
    canonical_family_ids: frozenset[str],
    max_families: int,
) -> tuple[str, ...]:
    picks = selection.families[: max(1, int(max_families))]
    ids = [p.family_id.strip() for p in picks if p.family_id.strip() != ""]
    if any(family_id not in canonical_family_ids for family_id in ids):
        bad = next((fid for fid in ids if fid not in canonical_family_ids), "")
        raise DoTemplateSelectionInvalidFamilyIdError(family_id=bad or "unknown")
    return tuple(ids)


def validated_template_id(
    *,
    selection: Stage2TemplateSelection,
    candidate_template_ids: frozenset[str],
) -> str:
    template_id = selection.template_id.strip()
    if template_id == "" or template_id not in candidate_template_ids:
        raise DoTemplateSelectionInvalidTemplateIdError(template_id=selection.template_id)
    return template_id

