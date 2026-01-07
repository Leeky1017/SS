from __future__ import annotations

import json
import os

import pytest

from src.infra.exceptions import (
    ArtifactPathUnsafeError,
    JobDataCorruptedError,
    JobVersionConflictError,
)
from src.utils.job_workspace import resolve_job_dir, shard_for_job_id


def test_load_with_valid_job_json_returns_job(job_service, store, jobs_dir):
    job = job_service.create_job(requirement="hello")

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    path = job_dir / "job.json"
    raw = json.loads(path.read_text(encoding="utf-8"))

    loaded = store.load(job.job_id)

    assert raw["schema_version"] == 3
    assert raw["version"] == 1
    assert loaded.schema_version == 3
    assert loaded.version == 1


def test_load_with_missing_schema_version_raises_job_data_corrupted_error(store, jobs_dir):
    job_id = "job_missing_schema_version"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text(
        json.dumps(
            {
                "job_id": job_id,
                "status": "created",
                "created_at": "2026-01-06T17:50:00+00:00",
                "requirement": None,
            }
        ),
        encoding="utf-8",
    )

    with pytest.raises(JobDataCorruptedError):
        store.load(job_id)


def test_load_with_unsupported_schema_version_raises_job_data_corrupted_error(store, jobs_dir):
    job_id = "job_unsupported_schema_version"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text(
        json.dumps(
            {
                "schema_version": 999,
                "job_id": job_id,
                "status": "created",
                "created_at": "2026-01-06T17:50:00+00:00",
                "requirement": None,
            }
        ),
        encoding="utf-8",
    )

    with pytest.raises(JobDataCorruptedError):
        store.load(job_id)


def test_load_with_invalid_artifact_rel_path_raises_job_data_corrupted_error(store, jobs_dir):
    job_id = "job_invalid_rel_path"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "job_id": job_id,
                "status": "created",
                "created_at": "2026-01-06T17:50:00+00:00",
                "requirement": None,
                "artifacts_index": [{"kind": "llm.prompt", "rel_path": "../escape.txt"}],
            }
        ),
        encoding="utf-8",
    )

    with pytest.raises(JobDataCorruptedError):
        store.load(job_id)


def test_load_with_corrupt_json_raises_job_data_corrupted_error(store, jobs_dir):
    job_id = "job_corrupt_json"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    (job_dir / "job.json").write_text("{", encoding="utf-8")

    with pytest.raises(JobDataCorruptedError):
        store.load(job_id)


def test_write_artifact_json_with_unsafe_rel_path_raises_artifact_path_unsafe_error(
    job_service,
    store,
):
    job = job_service.create_job(requirement="hello")

    with pytest.raises(ArtifactPathUnsafeError) as exc:
        store.write_artifact_json(
            job_id=job.job_id,
            rel_path="../escape.json",
            payload={"ok": True},
        )
    assert exc.value.error_code == "ARTIFACT_PATH_UNSAFE"


def test_write_artifact_json_with_symlink_escape_raises_artifact_path_unsafe_error(
    job_service,
    store,
    jobs_dir,
    tmp_path,
):
    job = job_service.create_job(requirement="hello")
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None

    outside_dir = tmp_path / "outside"
    outside_dir.mkdir(parents=True, exist_ok=True)

    artifacts_link = job_dir / "artifacts"
    os.symlink(outside_dir, artifacts_link)

    with pytest.raises(ArtifactPathUnsafeError) as exc:
        store.write_artifact_json(
            job_id=job.job_id,
            rel_path="artifacts/plan.json",
            payload={"ok": True},
        )
    assert exc.value.error_code == "ARTIFACT_PATH_UNSAFE"
    assert not (outside_dir / "plan.json").exists()


def test_save_with_stale_version_raises_job_version_conflict_error(job_service, store) -> None:
    job = job_service.create_job(requirement="hello")

    first = store.load(job.job_id)
    second = store.load(job.job_id)

    first.requirement = "first update"
    store.save(first)

    second.requirement = "second update"
    with pytest.raises(JobVersionConflictError):
        store.save(second)


def test_create_writes_job_json_to_sharded_path(job_service, jobs_dir) -> None:
    job = job_service.create_job(requirement="hello")
    shard = shard_for_job_id(job.job_id)
    assert (jobs_dir / shard / job.job_id / "job.json").exists()
    assert not (jobs_dir / job.job_id / "job.json").exists()


def test_save_with_legacy_job_dir_keeps_legacy_path(store, jobs_dir) -> None:
    job_id = "job_legacy_v3"
    legacy_dir = jobs_dir / job_id
    legacy_dir.mkdir(parents=True, exist_ok=True)
    legacy_path = legacy_dir / "job.json"
    legacy_path.write_text(
        json.dumps(
            {
                "schema_version": 3,
                "version": 1,
                "job_id": job_id,
                "status": "created",
                "created_at": "2026-01-06T17:50:00+00:00",
                "requirement": None,
                "runs": [],
                "artifacts_index": [],
            }
        ),
        encoding="utf-8",
    )

    loaded = store.load(job_id)
    loaded.requirement = "updated"
    store.save(loaded)

    persisted = json.loads(legacy_path.read_text(encoding="utf-8"))
    assert persisted["version"] == 2
    assert persisted["requirement"] == "updated"

    shard = shard_for_job_id(job_id)
    assert not (jobs_dir / shard / job_id / "job.json").exists()
