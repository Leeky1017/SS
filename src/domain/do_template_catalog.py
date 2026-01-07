from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class FamilySummary:
    family_id: str
    description: str
    capabilities: tuple[str, ...] = tuple()
    template_ids: tuple[str, ...] = tuple()


@dataclass(frozen=True)
class TemplateSummary:
    template_id: str
    family_id: str
    name: str
    slug: str
    placeholders: tuple[str, ...] = tuple()
    output_types: tuple[str, ...] = tuple()


class DoTemplateCatalog(Protocol):
    def list_families(self) -> tuple[FamilySummary, ...]: ...

    def list_templates(self, *, family_ids: tuple[str, ...]) -> tuple[TemplateSummary, ...]: ...

