from __future__ import annotations

from datetime import datetime, timedelta

from fastapi import APIRouter, Body, Depends, Query, Response

from src.api.admin.deps import get_task_code_store
from src.api.admin.schemas import (
    AdminTaskCodeCreateRequest,
    AdminTaskCodeItem,
    AdminTaskCodeListResponse,
)
from src.domain.task_code_store import TaskCodeRecord, TaskCodeStore
from src.utils.time import utc_now

router = APIRouter(prefix="/task-codes", tags=["admin-task-codes"])


@router.post("", response_model=AdminTaskCodeListResponse)
async def create_task_codes(
    payload: AdminTaskCodeCreateRequest = Body(default_factory=AdminTaskCodeCreateRequest),
    store: TaskCodeStore = Depends(get_task_code_store),
) -> AdminTaskCodeListResponse:
    now = utc_now()
    expires_at = now + timedelta(days=payload.expires_in_days)
    issued = store.issue_codes(
        tenant_id=payload.tenant_id,
        count=payload.count,
        expires_at=expires_at,
        now=now,
    )
    return AdminTaskCodeListResponse(task_codes=[_to_item(record, now=now) for record in issued])


@router.get("", response_model=AdminTaskCodeListResponse)
async def list_task_codes(
    tenant_id: str | None = Query(default=None),
    status: str | None = Query(default=None),
    store: TaskCodeStore = Depends(get_task_code_store),
) -> AdminTaskCodeListResponse:
    now = utc_now()
    items: list[AdminTaskCodeItem] = []
    for record in store.list_codes(tenant_id=tenant_id):
        item = _to_item(record, now=now)
        if status is not None and item.status != status:
            continue
        items.append(item)
    return AdminTaskCodeListResponse(task_codes=items)


@router.post("/{code_id}/revoke", response_model=AdminTaskCodeItem)
async def revoke_task_code(
    code_id: str,
    store: TaskCodeStore = Depends(get_task_code_store),
) -> AdminTaskCodeItem:
    now = utc_now()
    record = store.revoke(code_id=code_id, revoked_at=now)
    return _to_item(record, now=now)


@router.delete("/{code_id}", status_code=204)
async def delete_task_code(
    code_id: str,
    store: TaskCodeStore = Depends(get_task_code_store),
) -> Response:
    store.delete(code_id=code_id)
    return Response(status_code=204)


def _to_item(record: TaskCodeRecord, *, now: datetime) -> AdminTaskCodeItem:
    computed_status = record.status(now=now)
    return AdminTaskCodeItem(
        code_id=record.code_id,
        task_code=record.task_code,
        tenant_id=record.tenant_id,
        created_at=record.created_at,
        expires_at=record.expires_at,
        used_at=record.used_at,
        job_id=record.job_id,
        revoked_at=record.revoked_at,
        status=computed_status,
    )
