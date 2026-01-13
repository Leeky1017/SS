from __future__ import annotations

from fastapi import APIRouter, Depends

from src.api.admin.schemas import AdminTenantListResponse
from src.api.deps import get_config
from src.config import Config
from src.utils.tenancy import DEFAULT_TENANT_ID, TENANTS_DIRNAME, is_safe_tenant_id

router = APIRouter(prefix="/tenants", tags=["admin-tenants"])


@router.get("", response_model=AdminTenantListResponse)
async def list_tenants(config: Config = Depends(get_config)) -> AdminTenantListResponse:
    tenants = [DEFAULT_TENANT_ID]
    tenants_dir = config.jobs_dir / TENANTS_DIRNAME
    if tenants_dir.is_dir():
        for child in tenants_dir.iterdir():
            if child.is_dir() and is_safe_tenant_id(child.name):
                tenants.append(child.name)
    tenants.sort()
    return AdminTenantListResponse(tenants=tenants)

