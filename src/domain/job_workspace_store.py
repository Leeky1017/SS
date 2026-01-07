from __future__ import annotations

from pathlib import Path
from typing import Protocol

from src.utils.tenancy import DEFAULT_TENANT_ID


class JobWorkspaceStore(Protocol):
    def write_bytes(
        self,
        *,
        job_id: str,
        rel_path: str,
        data: bytes,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> None: ...

    def resolve_for_read(
        self,
        *,
        job_id: str,
        rel_path: str,
        tenant_id: str = DEFAULT_TENANT_ID,
    ) -> Path: ...

