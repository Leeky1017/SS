from __future__ import annotations

from fastapi import APIRouter, Body, Depends

from src.api.deps import get_task_code_redeem_service, get_tenant_id
from src.api.schemas import TaskCodeRedeemRequest, TaskCodeRedeemResponse
from src.domain.task_code_redeem_service import TaskCodeRedeemService

router = APIRouter(tags=["task-codes"])


@router.post("/task-codes/redeem", response_model=TaskCodeRedeemResponse)
async def redeem_task_code(
    payload: TaskCodeRedeemRequest = Body(...),
    tenant_id: str = Depends(get_tenant_id),
    svc: TaskCodeRedeemService = Depends(get_task_code_redeem_service),
) -> TaskCodeRedeemResponse:
    result = svc.redeem(
        tenant_id=tenant_id,
        task_code=payload.task_code,
        requirement=payload.requirement,
    )
    return TaskCodeRedeemResponse(
        job_id=result.job_id,
        token=result.token,
        expires_at=result.expires_at,
        is_idempotent=result.is_idempotent,
    )

