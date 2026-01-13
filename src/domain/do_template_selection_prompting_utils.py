from __future__ import annotations

import hashlib

from src.domain.do_template_catalog import FamilySummary, TemplateSummary


def sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def estimate_tokens(text: str) -> int:
    stripped = text.strip()
    if stripped == "":
        return 0
    return max(1, len(stripped) // 4)


def family_prompt_item(family: FamilySummary) -> dict[str, object]:
    return {
        "family_id": family.family_id,
        "description": family.description,
        "capabilities": list(family.capabilities),
        "n_templates": len(family.template_ids),
    }


def template_prompt_item(template: TemplateSummary) -> dict[str, object]:
    return {
        "template_id": template.template_id,
        "family_id": template.family_id,
        "name": template.name[:80],
        "slug": template.slug[:80],
        "placeholders": list(template.placeholders)[:8],
        "output_types": list(template.output_types)[:8],
    }

