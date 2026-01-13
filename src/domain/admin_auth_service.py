from __future__ import annotations

import secrets
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime

from src.domain.admin_token_store import AdminTokenIssued, AdminTokenMetadata, AdminTokenStore
from src.infra.admin_exceptions import AdminCredentialsInvalidError, AdminNotConfiguredError


@dataclass(frozen=True)
class AdminPrincipal:
    token_id: str
    name: str


class AdminAuthService:
    def __init__(
        self,
        *,
        expected_username: str,
        expected_password: str,
        tokens: AdminTokenStore,
        now: Callable[[], datetime],
    ):
        self._expected_username = expected_username
        self._expected_password = expected_password
        self._tokens = tokens
        self._now = now

    def login(self, *, username: str, password: str) -> AdminTokenIssued:
        if self._expected_password.strip() == "":
            raise AdminNotConfiguredError()
        if username != self._expected_username:
            raise AdminCredentialsInvalidError()
        if not secrets.compare_digest(password, self._expected_password):
            raise AdminCredentialsInvalidError()
        return self._tokens.issue_token(name=f"session:{username}", now=self._now())

    def authenticate(self, *, token: str) -> AdminPrincipal:
        meta = self._tokens.authenticate(token=token, now=self._now())
        return AdminPrincipal(token_id=meta.token_id, name=meta.name)

    def logout(self, *, token: str) -> AdminTokenMetadata:
        meta = self._tokens.authenticate(token=token, now=self._now())
        return self._tokens.revoke_token(token_id=meta.token_id, now=self._now())

