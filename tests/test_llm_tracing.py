from __future__ import annotations

import asyncio
import json
from pathlib import Path

import pytest

from src.domain.draft_service import DraftService
from src.domain.llm_client import LLMClient, LLMProviderError
from src.domain.models import ArtifactKind, Draft, Job
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import LLMCallFailedError
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient


def _read_job_artifact(*, jobs_dir: Path, job_id: str, rel_path: str) -> str:
    return (jobs_dir / job_id / rel_path).read_text(encoding="utf-8")


def test_preview_when_llm_succeeds_writes_llm_artifacts_and_redacts_secrets(
    job_service,
    draft_service,
    store,
    jobs_dir,
):
    # Arrange
    secret = "sk-0123456789abcdef0123456789abcdef"
    job = job_service.create_job(requirement=f"please use token {secret} for auth")

    # Act
    asyncio.run(draft_service.preview(job_id=job.job_id))

    # Assert
    loaded = store.load(job.job_id)
    prompt_paths = [
        a.rel_path for a in loaded.artifacts_index if a.kind == ArtifactKind.LLM_PROMPT
    ]
    response_paths = [
        a.rel_path
        for a in loaded.artifacts_index
        if a.kind == ArtifactKind.LLM_RESPONSE
    ]
    meta_paths = [a.rel_path for a in loaded.artifacts_index if a.kind == ArtifactKind.LLM_META]
    assert len(prompt_paths) == 1
    assert len(response_paths) == 1
    assert len(meta_paths) == 1

    prompt_text = _read_job_artifact(
        jobs_dir=jobs_dir,
        job_id=job.job_id,
        rel_path=prompt_paths[0],
    )
    response_text = _read_job_artifact(
        jobs_dir=jobs_dir,
        job_id=job.job_id,
        rel_path=response_paths[0],
    )
    meta = json.loads(
        _read_job_artifact(
            jobs_dir=jobs_dir,
            job_id=job.job_id,
            rel_path=meta_paths[0],
        )
    )

    assert secret not in prompt_text
    assert secret not in response_text
    assert "sk-<REDACTED>" in prompt_text
    assert "sk-<REDACTED>" in response_text
    assert meta["ok"] is True
    assert meta["model"] == "stub"


def test_preview_when_llm_fails_persists_llm_artifacts_and_raises_llm_call_failed_error(
    job_service,
    store: JobStore,
    jobs_dir: Path,
    state_machine: JobStateMachine,
):
    # Arrange
    secret = "sk-abcdef0123456789abcdef0123456789"

    class FailingLLMClient(LLMClient):
        async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
            raise LLMProviderError(f"provider failed with secret {secret}")

    llm = TracedLLMClient(
        inner=FailingLLMClient(),
        jobs_dir=jobs_dir,
        model="fake",
        temperature=None,
        seed=None,
    )
    svc = DraftService(store=store, llm=llm, state_machine=state_machine)
    job = job_service.create_job(requirement="trigger failure")

    # Act / Assert
    with pytest.raises(LLMCallFailedError):
        asyncio.run(svc.preview(job_id=job.job_id))

    loaded = store.load(job.job_id)
    meta_paths = [a.rel_path for a in loaded.artifacts_index if a.kind == ArtifactKind.LLM_META]
    assert len(meta_paths) == 1

    meta = json.loads(
        _read_job_artifact(
            jobs_dir=jobs_dir,
            job_id=job.job_id,
            rel_path=meta_paths[0],
        )
    )
    assert meta["ok"] is False
    assert meta["error_type"] == "LLMProviderError"
    assert meta["error_message"] is not None
    assert secret not in meta["error_message"]
