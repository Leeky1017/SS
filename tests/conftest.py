from __future__ import annotations

from pathlib import Path

import pytest

from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.llm_client import StubLLMClient
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient


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
    plan_service: PlanService,
) -> JobService:
    return JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        plan_service=plan_service,
        state_machine=state_machine,
        idempotency=idempotency,
    )


@pytest.fixture
def draft_service(store: JobStore, state_machine: JobStateMachine, jobs_dir: Path) -> DraftService:
    llm = TracedLLMClient(
        inner=StubLLMClient(),
        jobs_dir=jobs_dir,
        model="stub",
        temperature=0.0,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=3,
        retry_backoff_base_seconds=1.0,
        retry_backoff_max_seconds=30.0,
    )
    return DraftService(
        store=store,
        llm=llm,
        state_machine=state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )


@pytest.fixture
def plan_service(store: JobStore, jobs_dir: Path) -> PlanService:
    return PlanService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))
