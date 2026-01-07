from __future__ import annotations

from typing import Protocol

from src.domain.models import Draft, Job
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID


class JobStore(Protocol):
    def create(self, job: Job, *, tenant_id: str = DEFAULT_TENANT_ID) -> None: ...

    def load(self, job_id: str, *, tenant_id: str = DEFAULT_TENANT_ID) -> Job: ...

    def save(self, job: Job, *, tenant_id: str = DEFAULT_TENANT_ID) -> None: ...

    def write_draft(
        self,
        *,
        job_id: str,
        draft: Draft,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> None: ...

    def write_artifact_json(
        self,
        *,
        job_id: str,
        rel_path: str,
        payload: JsonObject,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> None: ...
