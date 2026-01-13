from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True)
class AdminTokenMetadata:
    token_id: str
    name: str
    created_at: str
    last_used_at: str | None = None
    revoked_at: str | None = None


@dataclass(frozen=True)
class AdminTokenIssued:
    token_id: str
    token: str
    created_at: str


class AdminTokenStore(Protocol):
    def issue_token(self, *, name: str, now: datetime) -> AdminTokenIssued: ...

    def list_tokens(self) -> list[AdminTokenMetadata]: ...

    def revoke_token(self, *, token_id: str, now: datetime) -> AdminTokenMetadata: ...

    def delete_token(self, *, token_id: str) -> None: ...

    def authenticate(self, *, token: str, now: datetime) -> AdminTokenMetadata: ...

