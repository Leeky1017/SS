from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api.admin import auth, jobs, system, task_codes, tenants, tokens
from src.api.admin.deps import require_admin_principal

router = APIRouter(prefix="/api/admin", tags=["admin"])

router.include_router(auth.router)
router.include_router(tokens.router, dependencies=[Depends(require_admin_principal)])
router.include_router(task_codes.router, dependencies=[Depends(require_admin_principal)])
router.include_router(jobs.router, dependencies=[Depends(require_admin_principal)])
router.include_router(system.router, dependencies=[Depends(require_admin_principal)])
router.include_router(tenants.router, dependencies=[Depends(require_admin_principal)])

