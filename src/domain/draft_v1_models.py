from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field

from src.utils.json_types import JsonScalar


class DraftStage1Option(BaseModel):
    model_config = ConfigDict(extra="forbid")

    option_id: str
    label: str
    value: JsonScalar


class DraftStage1Question(BaseModel):
    model_config = ConfigDict(extra="forbid")

    question_id: str
    question_text: str
    question_type: str
    options: list[DraftStage1Option] = Field(default_factory=list)
    priority: int = 0


class DraftOpenUnknown(BaseModel):
    model_config = ConfigDict(extra="forbid")

    field: str
    description: str
    impact: str
    blocking: bool | None = None
    candidates: list[str] = Field(default_factory=list)
