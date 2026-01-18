from __future__ import annotations

from pydantic import BaseModel, Field


class DraftRequiredVariable(BaseModel):
    field: str
    description: str
    candidates: list[str] = Field(default_factory=list)
