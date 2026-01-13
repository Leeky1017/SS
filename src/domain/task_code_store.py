from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Literal, Protocol

from src.utils.tenancy import DEFAULT_TENANT_ID

TaskCodeStatus = Literal["unused", "used", "expired", "revoked"]


@dataclass(frozen=True)
class TaskCodeRecord:
    code_id: str
    task_code: str
    tenant_id: str = DEFAULT_TENANT_ID
    created_at: str = ""
    expires_at: str = ""
    used_at: str | None = None
    job_id: str | None = None
    revoked_at: str | None = None

    def status(self, *, now: datetime) -> TaskCodeStatus:
        if isinstance(self.revoked_at, str) and self.revoked_at.strip() != "":
            return "revoked"
        if isinstance(self.used_at, str) and self.used_at.strip() != "":
            return "used"
        try:
            expires_at = datetime.fromisoformat(self.expires_at)
        except ValueError:
            return "expired"
        try:
            return "expired" if expires_at <= now else "unused"
        except TypeError:
            return "expired"


class TaskCodeStore(Protocol):
    def issue_codes(
        self,
        *,
        tenant_id: str,
        count: int,
        expires_at: datetime,
        now: datetime,
    ) -> list[TaskCodeRecord]: ...

    def list_codes(self, *, tenant_id: str | None = None) -> list[TaskCodeRecord]: ...

    def find_by_code(self, *, tenant_id: str, task_code: str) -> TaskCodeRecord | None: ...

    def get(self, *, code_id: str) -> TaskCodeRecord | None: ...

    def mark_used(self, *, code_id: str, job_id: str, used_at: datetime) -> TaskCodeRecord: ...

    def revoke(self, *, code_id: str, revoked_at: datetime) -> TaskCodeRecord: ...

    def delete(self, *, code_id: str) -> None: ...
