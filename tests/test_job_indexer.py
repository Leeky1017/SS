from __future__ import annotations

import json
from pathlib import Path

from src.infra.file_job_indexer import FileJobIndexer


def _write_job_json(*, root: Path, job_id: str, status: str, created_at: str) -> None:
    job_dir = root / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text(
        json.dumps({"job_id": job_id, "status": status, "created_at": created_at}),
        encoding="utf-8",
    )


def test_list_jobs_includes_default_and_tenant_jobs(tmp_path: Path) -> None:
    jobs_dir = tmp_path / "jobs"
    tenants_dir = jobs_dir / "tenants" / "tenant-a"

    _write_job_json(
        root=jobs_dir,
        job_id="job_default",
        status="created",
        created_at="2026-01-01T00:00:00+00:00",
    )
    _write_job_json(
        root=tenants_dir,
        job_id="job_tenant_a",
        status="failed",
        created_at="2026-01-01T00:00:01+00:00",
    )

    indexer = FileJobIndexer(jobs_dir=jobs_dir)
    items = indexer.list_jobs()

    assert {item.job_id for item in items} == {"job_default", "job_tenant_a"}
    assert any(item.tenant_id == "default" and item.job_id == "job_default" for item in items)
    assert any(item.tenant_id == "tenant-a" and item.job_id == "job_tenant_a" for item in items)
