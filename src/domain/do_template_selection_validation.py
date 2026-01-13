from __future__ import annotations

from src.domain.do_template_selection_models import (
    Stage1FamilySelection,
    Stage1FamilySelectionV2,
    Stage2TemplateSelection,
    Stage2TemplateSelectionV2,
)
from src.infra.do_template_selection_exceptions import (
    DoTemplateSelectionInvalidFamilyIdError,
    DoTemplateSelectionInvalidTemplateIdError,
)


def validated_family_ids(
    *,
    selection: Stage1FamilySelection | Stage1FamilySelectionV2,
    canonical_family_ids: frozenset[str],
    max_families: int,
) -> tuple[str, ...]:
    picks = selection.families[: max(1, int(max_families))]
    ids = [p.family_id.strip() for p in picks if p.family_id.strip() != ""]
    if any(family_id not in canonical_family_ids for family_id in ids):
        bad = next((fid for fid in ids if fid not in canonical_family_ids), "")
        family_id = bad if bad != "" else "unknown"
        raise DoTemplateSelectionInvalidFamilyIdError(family_id=family_id)
    return tuple(ids)


def validated_template_selection(
    *,
    selection: Stage2TemplateSelection | Stage2TemplateSelectionV2,
    candidate_template_ids: frozenset[str],
) -> tuple[str, tuple[str, ...]]:
    if isinstance(selection, Stage2TemplateSelectionV2):
        primary = selection.primary_template_id.strip()
        if primary == "" or primary not in candidate_template_ids:
            raise DoTemplateSelectionInvalidTemplateIdError(
                template_id=selection.primary_template_id
            )
        seen = {primary}
        supplementary: list[str] = []
        for item in selection.supplementary_templates:
            template_id = item.template_id.strip()
            if (
                template_id == ""
                or template_id not in candidate_template_ids
                or template_id in seen
            ):
                raise DoTemplateSelectionInvalidTemplateIdError(template_id=item.template_id)
            seen.add(template_id)
            supplementary.append(template_id)
        return primary, tuple(supplementary)

    template_id = selection.template_id.strip()
    if template_id == "" or template_id not in candidate_template_ids:
        raise DoTemplateSelectionInvalidTemplateIdError(template_id=selection.template_id)
    return template_id, tuple()
