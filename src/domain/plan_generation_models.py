from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from src.domain.models import Draft


class DataSchema(BaseModel):
    model_config = ConfigDict(extra="forbid")

    columns: list[str] = Field(default_factory=list)
    n_rows: int | None = None
    has_panel_structure: bool = False
    detected_vars: dict[str, str | None] = Field(default_factory=dict)


class PlanConstraints(BaseModel):
    model_config = ConfigDict(extra="forbid")

    max_steps: int = Field(ge=1)
    required_outputs: list[str] = Field(default_factory=list)


class PlanGenerationInput(BaseModel):
    model_config = ConfigDict(extra="forbid")

    job_id: str
    requirement: str
    draft: Draft | None = None
    selected_templates: list[str] = Field(default_factory=list)
    data_schema: DataSchema
    constraints: PlanConstraints

