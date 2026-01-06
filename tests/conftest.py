from __future__ import annotations

from pathlib import Path

import pytest

from src.domain.draft_service import DraftService
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.llm_client import StubLLMClient
from src.infra.job_store import JobStore


@pytest.fixture
def jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def store(jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=jobs_dir)


@pytest.fixture
def job_service(store: JobStore) -> JobService:
    return JobService(store=store, scheduler=NoopJobScheduler())


@pytest.fixture
def draft_service(store: JobStore) -> DraftService:
    return DraftService(store=store, llm=StubLLMClient())
