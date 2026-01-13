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


class Stage1FamilySelectionV2(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=2)
    families: list[Stage1FamilyPick] = Field(default_factory=list)
    analysis_sequence: list[str] = Field(default_factory=list)
    requires_combination: bool = False
    combination_reason: str = ""


class Stage2TemplateSelection(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=1)
    template_id: str
    reason: str
    confidence: float = Field(ge=0.0, le=1.0)


class Stage2SupplementaryTemplatePick(BaseModel):
    model_config = ConfigDict(extra="forbid")

    template_id: str
    purpose: str
    sequence_order: int = Field(ge=1)
    confidence: float = Field(ge=0.0, le=1.0)


class Stage2TemplateSelectionV2(BaseModel):
    model_config = ConfigDict(extra="forbid")

    schema_version: int = Field(default=2)
    primary_template_id: str
    primary_reason: str
    primary_confidence: float = Field(ge=0.0, le=1.0)
    supplementary_templates: list[Stage2SupplementaryTemplatePick] = Field(default_factory=list)


@dataclass(frozen=True)
class DoTemplateSelectionResult:
    selected_family_ids: tuple[str, ...]
    candidate_template_ids: tuple[str, ...]
    selected_template_id: str
    supplementary_template_ids: tuple[str, ...] = tuple()
    analysis_sequence: tuple[str, ...] = tuple()
    requires_combination: bool = False
    requires_user_confirmation: bool = False
    used_manual_fallback: bool = False
    primary_confidence: float | None = None
