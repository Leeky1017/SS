from __future__ import annotations

from pathlib import Path

DEFAULT_TENANT_ID = "default"
TENANTS_DIRNAME = "tenants"


def is_safe_tenant_id(tenant_id: str) -> bool:
    if tenant_id == "":
        return False
    if tenant_id.startswith("~"):
        return False
    if "/" in tenant_id or "\\" in tenant_id:
        return False
    return tenant_id not in {".", ".."}


def tenant_jobs_dir(*, jobs_dir: Path, tenant_id: str) -> Path | None:
    if tenant_id == DEFAULT_TENANT_ID:
        return Path(jobs_dir)
    if not is_safe_tenant_id(tenant_id):
        return None
    return Path(jobs_dir) / TENANTS_DIRNAME / tenant_id
