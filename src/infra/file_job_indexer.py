from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from pathlib import Path
from typing import cast

from src.domain.job_indexer import JobIndexer, JobIndexItem
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID, TENANTS_DIRNAME, is_safe_tenant_id

logger = logging.getLogger(__name__)


class FileJobIndexer(JobIndexer):
    def __init__(self, *, jobs_dir: Path):
        self._jobs_dir = Path(jobs_dir)

    def list_jobs(self, *, tenant_id: str | None = None) -> list[JobIndexItem]:
        items: list[JobIndexItem] = []
        for resolved_tenant_id, root in self._iter_tenant_roots(tenant_id=tenant_id):
            items.extend(self._list_tenant_jobs(tenant_id=resolved_tenant_id, root=root))
        items.sort(key=lambda item: item.updated_at or item.created_at, reverse=True)
        return items

    def _iter_tenant_roots(self, *, tenant_id: str | None) -> list[tuple[str, Path]]:
        if tenant_id is not None:
            resolved = tenant_id.strip()
            resolved = DEFAULT_TENANT_ID if resolved == "" else resolved
            if resolved == DEFAULT_TENANT_ID:
                return [(DEFAULT_TENANT_ID, self._jobs_dir)]
            if not is_safe_tenant_id(resolved):
                return []
            return [(resolved, self._jobs_dir / TENANTS_DIRNAME / resolved)]

        roots: list[tuple[str, Path]] = [(DEFAULT_TENANT_ID, self._jobs_dir)]
        tenants_dir = self._jobs_dir / TENANTS_DIRNAME
        if tenants_dir.is_dir():
            for child in tenants_dir.iterdir():
                if not child.is_dir():
                    continue
                if is_safe_tenant_id(child.name):
                    roots.append((child.name, child))
        return roots

    def _list_tenant_jobs(self, *, tenant_id: str, root: Path) -> list[JobIndexItem]:
        if not root.is_dir():
            return []
        items: list[JobIndexItem] = []
        for job_json in self._iter_job_json_paths(root=root, include_tenants=False):
            summary = _read_job_summary(path=job_json, tenant_id=tenant_id)
            if summary is not None:
                items.append(summary)
        return items

    def _iter_job_json_paths(self, *, root: Path, include_tenants: bool) -> list[Path]:
        job_jsons: list[Path] = []
        try:
            children = list(root.iterdir())
        except OSError as e:
            logger.warning("SS_JOB_INDEX_LIST_FAILED", extra={"root": str(root), "error": str(e)})
            return []

        for child in children:
            if not child.is_dir():
                continue
            if not include_tenants and child.name in {TENANTS_DIRNAME, "_admin"}:
                continue
            legacy = child / "job.json"
            if legacy.is_file():
                job_jsons.append(legacy)
                continue
            try:
                shard_children = list(child.iterdir())
            except OSError:
                continue
            for job_dir in shard_children:
                if not job_dir.is_dir():
                    continue
                job_json = job_dir / "job.json"
                if job_json.is_file():
                    job_jsons.append(job_json)
        return job_jsons


def _read_job_summary(*, path: Path, tenant_id: str) -> JobIndexItem | None:
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as e:
        logger.warning("SS_JOB_INDEX_READ_FAILED", extra={"path": str(path), "error": str(e)})
        return None
    if not isinstance(raw, dict):
        logger.warning("SS_JOB_INDEX_INVALID", extra={"path": str(path), "reason": "not_object"})
        return None
    payload = cast(JsonObject, raw)
    job_id = str(payload.get("job_id", "")).strip()
    status = str(payload.get("status", "")).strip()
    created_at = str(payload.get("created_at", "")).strip()
    updated_at = _mtime_iso(path)
    if job_id == "":
        return None
    return JobIndexItem(
        tenant_id=tenant_id,
        job_id=job_id,
        status=status,
        created_at=created_at,
        updated_at=updated_at,
    )


def _mtime_iso(path: Path) -> str | None:
    try:
        ts = path.stat().st_mtime
    except OSError:
        return None
    return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()
