from __future__ import annotations

import asyncio
from pathlib import Path

import pytest

from src.domain.llm_client import StubLLMClient
from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job
from src.infra.exceptions import LLMArtifactsWriteError
from src.infra.llm_tracing import TracedLLMClient
from src.utils.job_workspace import shard_for_job_id
from src.utils.time import utc_now


@pytest.mark.anyio
async def test_draft_preview_when_artifacts_dir_not_writable_returns_clear_error(
    client, job_service, store, job_dir_for
) -> None:
    job = job_service.create_job(requirement="hello")
    job_dir = job_dir_for(job.job_id)
    artifacts_root = job_dir / "artifacts"
    artifacts_root.mkdir(parents=True, exist_ok=True)

    try:
        artifacts_root.chmod(0o500)
        response = await client.get(f"/v1/jobs/{job.job_id}/draft/preview")
    finally:
        artifacts_root.chmod(0o700)

    assert response.status_code == 500
    payload = response.json()
    assert payload["error_code"] == "LLM_ARTIFACTS_WRITE_FAILED"
    assert "Traceback" not in payload["message"]

    persisted = store.load(job.job_id)
    assert persisted.artifacts_index == []


def test_llm_tracing_when_artifacts_dir_not_writable_raises_llm_artifacts_write_error(fs) -> None:
    jobs_dir = Path("/jobs")
    job_id = "job_perm_loss"
    shard = shard_for_job_id(job_id)
    job_dir = jobs_dir / shard / job_id
    artifacts_dir = job_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)
    artifacts_dir.chmod(0o500)

    llm = TracedLLMClient(
        inner=StubLLMClient(),
        jobs_dir=jobs_dir,
        model="fake",
        temperature=None,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )
    job = Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        job_id=job_id,
        created_at=utc_now().isoformat(),
    )

    with pytest.raises(LLMArtifactsWriteError) as exc:
        asyncio.run(llm.draft_preview(job=job, prompt="hello"))
    assert exc.value.error_code == "LLM_ARTIFACTS_WRITE_FAILED"
