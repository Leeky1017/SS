from __future__ import annotations

from pydantic import BaseModel, ConfigDict


class DraftColumnCandidateV2(BaseModel):
    model_config = ConfigDict(extra="forbid")

    dataset_key: str
    role: str
    name: str
