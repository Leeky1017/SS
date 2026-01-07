from __future__ import annotations

from dataclasses import dataclass

from pydantic import BaseModel, ConfigDict, Field


class Stage1FamilyPick(BaseModel):
    model_config = ConfigDict(extra="forbid")

    family_id: str
    reason: str
    confidence: float = Field(ge=0.0, le=1.0)


class Stage1FamilySelection(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=1)
    families: list[Stage1FamilyPick] = Field(default_factory=list)


class Stage2TemplateSelection(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=1)
    template_id: str
    reason: str
    confidence: float = Field(ge=0.0, le=1.0)


@dataclass(frozen=True)
class DoTemplateSelectionResult:
    selected_family_ids: tuple[str, ...]
    candidate_template_ids: tuple[str, ...]
    selected_template_id: str

