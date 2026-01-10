from __future__ import annotations

import os
from pathlib import Path

import pytest

from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.job_support import NoopJobScheduler
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient
from tests.fakes.fake_llm_client import FakeLLMClient

os.environ.setdefault("SS_LLM_PROVIDER", "yunwu")
os.environ.setdefault("SS_LLM_API_KEY", "test-key")


@pytest.fixture
def jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def do_template_library_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "assets" / "stata_do_library"


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
def draft_service(
    store: JobStore,
    state_machine: JobStateMachine,
    jobs_dir: Path,
    do_template_library_dir: Path,
) -> DraftService:
    llm = TracedLLMClient(
        inner=FakeLLMClient(),
        jobs_dir=jobs_dir,
        model="fake",
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
        do_template_selection=DoTemplateSelectionService(
            store=store,
            llm=llm,
            catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
        ),
    )


@pytest.fixture
def plan_service(store: JobStore, jobs_dir: Path, do_template_library_dir: Path) -> PlanService:
    return PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir),
    )
