from __future__ import annotations

import json

import pytest

from src.infra.exceptions import JobDataCorruptedError


def test_load_with_valid_job_json_returns_job(job_service, store, jobs_dir):
    job = job_service.create_job(requirement="hello")

    path = jobs_dir / job.job_id / "job.json"
    raw = json.loads(path.read_text(encoding="utf-8"))

    loaded = store.load(job.job_id)

    assert raw["schema_version"] == 1
    assert loaded.schema_version == 1


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

