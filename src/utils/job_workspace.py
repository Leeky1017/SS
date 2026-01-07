from __future__ import annotations

from pathlib import Path

SHARD_PREFIX_LEN = 2


def is_safe_path_segment(value: str) -> bool:
    if value == "":
        return False
    if value.startswith("~"):
        return False
    if "/" in value or "\\" in value:
        return False
    return value not in {".", ".."}


def shard_for_job_id(job_id: str) -> str:
    core = job_id
    if job_id.startswith("job_") and len(job_id) > 4:
        core = job_id[4:]
    if core == "":
        core = job_id
    if len(core) >= SHARD_PREFIX_LEN:
        return core[:SHARD_PREFIX_LEN]
    return (core + ("0" * SHARD_PREFIX_LEN))[:SHARD_PREFIX_LEN]


def _safe_child_dir(*, base_dir: Path, parts: tuple[str, ...]) -> Path | None:
    if not all(is_safe_path_segment(part) for part in parts):
        return None
    base = base_dir.resolve(strict=False)
    candidate = base_dir
    for part in parts:
        candidate = candidate / part
    resolved = candidate.resolve(strict=False)
    if not resolved.is_relative_to(base):
        return None
    return resolved


def sharded_job_dir(*, jobs_dir: Path, job_id: str) -> Path | None:
    shard = shard_for_job_id(job_id)
    return _safe_child_dir(base_dir=jobs_dir, parts=(shard, job_id))


def legacy_job_dir(*, jobs_dir: Path, job_id: str) -> Path | None:
    return _safe_child_dir(base_dir=jobs_dir, parts=(job_id,))


def resolve_job_dir(*, jobs_dir: Path, job_id: str) -> Path | None:
    sharded = sharded_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    legacy = legacy_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    if sharded is None:
        return None
    if (sharded / "job.json").exists():
        return sharded
    if legacy is not None and (legacy / "job.json").exists():
        return legacy
    return sharded

