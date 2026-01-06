from __future__ import annotations

from pathlib import Path

import pytest

from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.llm_client import StubLLMClient
from src.domain.state_machine import JobStateMachine
from src.infra.job_store import JobStore


@pytest.fixture
def jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def store(jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=jobs_dir)


@pytest.fixture
def state_machine() -> JobStateMachine:
    return JobStateMachine()


@pytest.fixture
def idempotency() -> JobIdempotency:
    return JobIdempotency()


@pytest.fixture
def job_service(
    store: JobStore,
    state_machine: JobStateMachine,
    idempotency: JobIdempotency,
) -> JobService:
    return JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        state_machine=state_machine,
        idempotency=idempotency,
    )


@pytest.fixture
def draft_service(store: JobStore, state_machine: JobStateMachine) -> DraftService:
    return DraftService(store=store, llm=StubLLMClient(), state_machine=state_machine)
