from __future__ import annotations

import json
from unittest.mock import patch

import pytest

from src.infra.exceptions import JobStoreIOError


def test_job_store_save_when_disk_full_does_not_corrupt_and_allows_retry(
    job_service,
    store,
    job_dir_for,
    enospc_error: OSError,
) -> None:
    job = job_service.create_job(requirement="base")
    job_dir = job_dir_for(job.job_id)
    job_path = job_dir / "job.json"
    before = job_path.read_text(encoding="utf-8")

    loaded = store.load(job.job_id)
    loaded.requirement = "update"

    with patch("src.infra.job_store.os.replace", side_effect=enospc_error):
        with pytest.raises(JobStoreIOError) as exc:
            store.save(loaded)
        assert exc.value.error_code == "JOB_STORE_IO_ERROR"

    after = job_path.read_text(encoding="utf-8")
    assert after == before
    assert json.loads(after)["requirement"] == "base"

    files = sorted(p.name for p in job_dir.iterdir() if p.is_file())
    assert files == ["job.json", "job.json.lock"]

    store.save(loaded)
    persisted = store.load(job.job_id)
    assert persisted.requirement == "update"


@pytest.mark.anyio
async def test_draft_preview_when_llm_artifact_write_hits_disk_full_returns_clear_error(
    client,
    store,
    job_service,
    job_dir_for,
    enospc_error: OSError,
) -> None:
    job = job_service.create_job(requirement="hello")
    job_dir = job_dir_for(job.job_id)

    with patch("src.infra.llm_tracing.os.replace", side_effect=enospc_error):
        response = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")

    assert response.status_code == 500
    payload = response.json()
    assert payload["error_code"] == "LLM_ARTIFACTS_WRITE_FAILED"
    assert "Traceback" not in payload["message"]

    persisted = store.load(job.job_id)
    assert persisted.artifacts_index == []

    files = [p for p in job_dir.rglob("*") if p.is_file()]
    assert sorted(p.name for p in files) == ["job.json", "job.json.lock"]
