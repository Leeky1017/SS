from __future__ import annotations

from pydantic import BaseModel


class DraftColumnNameNormalization(BaseModel):
    dataset_key: str
    role: str
    original_name: str
    normalized_name: str
