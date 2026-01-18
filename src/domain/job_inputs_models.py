from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class DatasetUpload:
    role: str
    data: bytes
    original_name: str | None
    filename_override: str | None
    content_type: str | None

