from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from src.utils.job_workspace import resolve_job_dir
from src.utils.tenancy import DEFAULT_TENANT_ID


@dataclass(frozen=True)
class RunDirs:
    job_dir: Path
    run_dir: Path
    work_dir: Path
    artifacts_dir: Path


def safe_segment(value: str) -> bool:
    if value == "":
        return False
    if "/" in value or "\\" in value:
        return False
    if value in {".", ".."}:
        return False
    return True


def job_rel_path(*, job_dir: Path, path: Path) -> str:
    return path.relative_to(job_dir).as_posix()


def resolve_run_dirs(
    *,
    jobs_dir: Path,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    run_id: str,
) -> RunDirs | None:
    if not safe_segment(job_id) or not safe_segment(run_id):
        return None

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, tenant_id=tenant_id, job_id=job_id)
    if job_dir is None:
        return None

    run_dir = (job_dir / "runs" / run_id).resolve()
    if not run_dir.is_relative_to(job_dir):
        return None

    work_dir = (run_dir / "work").resolve(strict=False)
    if not work_dir.is_relative_to(run_dir):
        return None

    artifacts_dir = (run_dir / "artifacts").resolve(strict=False)
    if not artifacts_dir.is_relative_to(run_dir):
        return None
    return RunDirs(job_dir=job_dir, run_dir=run_dir, work_dir=work_dir, artifacts_dir=artifacts_dir)

