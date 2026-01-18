from __future__ import annotations

from pydantic import BaseModel


class DraftColumnCandidateV2(BaseModel):
    dataset_key: str
    role: str
    name: str
