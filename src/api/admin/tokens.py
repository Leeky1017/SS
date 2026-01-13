from __future__ import annotations

from fastapi import APIRouter, Body, Depends, Response

from src.api.admin.deps import get_admin_token_store
from src.api.admin.schemas import (
    AdminTokenCreateRequest,
    AdminTokenCreateResponse,
    AdminTokenItem,
    AdminTokenListResponse,
)
from src.domain.admin_token_store import AdminTokenStore
from src.utils.time import utc_now

router = APIRouter(prefix="/tokens", tags=["admin-tokens"])


@router.get("", response_model=AdminTokenListResponse)
async def list_admin_tokens(
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> AdminTokenListResponse:
    items = [
        AdminTokenItem(
            token_id=token.token_id,
            name=token.name,
            created_at=token.created_at,
            last_used_at=token.last_used_at,
            revoked_at=token.revoked_at,
        )
        for token in tokens.list_tokens()
    ]
    return AdminTokenListResponse(tokens=items)


@router.post("", response_model=AdminTokenCreateResponse)
async def create_admin_token(
    payload: AdminTokenCreateRequest = Body(default_factory=AdminTokenCreateRequest),
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> AdminTokenCreateResponse:
    issued = tokens.issue_token(name=payload.name, now=utc_now())
    return AdminTokenCreateResponse(
        token=issued.token,
        token_id=issued.token_id,
        created_at=issued.created_at,
    )


@router.post("/{token_id}/revoke", response_model=AdminTokenItem)
async def revoke_admin_token(
    token_id: str,
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> AdminTokenItem:
    meta = tokens.revoke_token(token_id=token_id, now=utc_now())
    return AdminTokenItem(
        token_id=meta.token_id,
        name=meta.name,
        created_at=meta.created_at,
        last_used_at=meta.last_used_at,
        revoked_at=meta.revoked_at,
    )


@router.delete("/{token_id}", status_code=204)
async def delete_admin_token(
    token_id: str,
    tokens: AdminTokenStore = Depends(get_admin_token_store),
) -> Response:
    tokens.delete_token(token_id=token_id)
    return Response(status_code=204)
