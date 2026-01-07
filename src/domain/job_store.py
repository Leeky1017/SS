from __future__ import annotations

from typing import Protocol

from src.domain.models import Draft, Job
from src.utils.json_types import JsonObject


class JobStore(Protocol):
    def create(self, job: Job) -> None: ...

    def load(self, job_id: str) -> Job: ...

    def save(self, job: Job) -> None: ...

    def write_draft(self, *, job_id: str, draft: Draft) -> None: ...

    def write_artifact_json(self, *, job_id: str, rel_path: str, payload: JsonObject) -> None: ...

