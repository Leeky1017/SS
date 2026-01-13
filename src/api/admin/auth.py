from __future__ import annotations

from fastapi import APIRouter, Body, Depends

from src.api.admin.deps import (
    get_admin_auth_service,
    get_admin_token_store,
    require_admin_principal,
)
from src.api.admin.schemas import (
    AdminLoginRequest,
    AdminLoginResponse,
    AdminLogoutResponse,
)
from src.domain.admin_auth_service import AdminAuthService, AdminPrincipal
from src.domain.admin_token_store import AdminTokenStore
from src.utils.time import utc_now

router = APIRouter(prefix="/auth", tags=["admin-auth"])


@router.post("/login", response_model=AdminLoginResponse)
async def admin_login(
    payload: AdminLoginRequest = Body(...),
    auth: AdminAuthService = Depends(get_admin_auth_service),
) -> AdminLoginResponse:
    issued = auth.login(username=payload.username, password=payload.password)
    return AdminLoginResponse(
        token=issued.token,
        token_id=issued.token_id,
        created_at=issued.created_at,
    )


@router.post("/logout", response_model=AdminLogoutResponse)
async def admin_logout(
    principal: AdminPrincipal = Depends(require_admin_principal),
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> AdminLogoutResponse:
    revoked = tokens.revoke_token(token_id=principal.token_id, now=utc_now())
    return AdminLogoutResponse(token_id=revoked.token_id, revoked_at=revoked.revoked_at)
