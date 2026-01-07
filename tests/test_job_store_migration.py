from __future__ import annotations

import json
import logging


def test_load_with_v1_job_json_migrates_to_v3_and_persists(store, jobs_dir, caplog) -> None:
    # Arrange
    caplog.set_level(logging.INFO, logger="src.infra.job_store")
    job_id = "job_v1_migration"
    job_dir = jobs_dir / job_id
    job_dir.mkdir(parents=True, exist_ok=True)
    path = job_dir / "job.json"
    path.write_text(
        json.dumps(
            {
                "schema_version": 1,
                "job_id": job_id,
                "status": "created",
                "created_at": "2026-01-06T17:50:00+00:00",
                "requirement": None,
            }
        ),
        encoding="utf-8",
    )

    # Act
    loaded = store.load(job_id)

    # Assert
    assert loaded.schema_version == 3
    assert loaded.version == 1

    persisted = json.loads(path.read_text(encoding="utf-8"))
    assert persisted["schema_version"] == 3
    assert persisted["version"] == 1
    assert persisted["runs"] == []
    assert persisted["artifacts_index"] == []

    records = [r for r in caplog.records if r.getMessage() == "SS_JOB_JSON_SCHEMA_MIGRATED"]
    assert len(records) == 2
    steps = [(getattr(r, "from_version"), getattr(r, "to_version")) for r in records]
    assert steps == [(1, 2), (2, 3)]
    assert all(getattr(r, "job_id") == job_id for r in records)
