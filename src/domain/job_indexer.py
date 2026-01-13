from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from src.utils.tenancy import DEFAULT_TENANT_ID


@dataclass(frozen=True)
class JobIndexItem:
    job_id: str
    status: str
    created_at: str
    updated_at: str | None = None
    tenant_id: str = DEFAULT_TENANT_ID


class JobIndexer(Protocol):
    def list_jobs(self, *, tenant_id: str | None = None) -> list[JobIndexItem]: ...

