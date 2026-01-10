from __future__ import annotations

import os
from collections.abc import Callable, Iterator
from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.do_file_generator import DoFileGenerator
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.llm_client import StubLLMClient
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.main import create_app
from tests.fakes.fake_stata_runner import FakeStataRunner


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line("markers", "stress: stress/load tests (skipped by default)")


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    if os.getenv("SS_RUN_STRESS_TESTS") == "1":
        return
    skip = pytest.mark.skip(reason="Set SS_RUN_STRESS_TESTS=1 to run stress tests")
    for item in items:
        if "stress" in item.keywords:
            item.add_marker(skip)


@pytest.fixture
def stress_jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def stress_queue_dir(tmp_path: Path) -> Path:
    return tmp_path / "queue"


@pytest.fixture
def stress_store(stress_jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=stress_jobs_dir)


@pytest.fixture
def stress_state_machine() -> JobStateMachine:
    return JobStateMachine()


@pytest.fixture
def stress_idempotency() -> JobIdempotency:
    return JobIdempotency()


@pytest.fixture
def stress_queue(stress_queue_dir: Path) -> FileWorkerQueue:
    return FileWorkerQueue(queue_dir=stress_queue_dir, lease_ttl_seconds=60)


@pytest.fixture
def stress_job_service(
    stress_store: JobStore,
    stress_state_machine: JobStateMachine,
    stress_idempotency: JobIdempotency,
    stress_queue: FileWorkerQueue,
    stress_jobs_dir: Path,
) -> JobService:
    scheduler = QueueJobScheduler(queue=stress_queue)
    library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
    return JobService(
        store=stress_store,
        scheduler=scheduler,
        plan_service=PlanService(
            store=stress_store,
            workspace=FileJobWorkspaceStore(jobs_dir=stress_jobs_dir),
            do_template_catalog=FileSystemDoTemplateCatalog(library_dir=library_dir),
            do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir),
        ),
        state_machine=stress_state_machine,
        idempotency=stress_idempotency,
    )


@pytest.fixture
def stress_draft_service(
    stress_store: JobStore,
    stress_state_machine: JobStateMachine,
    stress_jobs_dir: Path,
) -> DraftService:
    llm = TracedLLMClient(
        inner=StubLLMClient(),
        jobs_dir=stress_jobs_dir,
        model="stub",
        temperature=0.0,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=3,
        retry_backoff_base_seconds=1.0,
        retry_backoff_max_seconds=30.0,
    )
    return DraftService(
        store=stress_store,
        llm=llm,
        state_machine=stress_state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=stress_jobs_dir),
    )


@pytest.fixture
def stress_artifacts_service(stress_store: JobStore, stress_jobs_dir: Path) -> ArtifactsService:
    return ArtifactsService(store=stress_store, jobs_dir=stress_jobs_dir)


@pytest.fixture
def stress_worker_factory(
    stress_store: JobStore,
    stress_queue: FileWorkerQueue,
    stress_jobs_dir: Path,
    stress_state_machine: JobStateMachine,
) -> Callable[[], WorkerService]:
    def _factory() -> WorkerService:
        runner = FakeStataRunner(jobs_dir=stress_jobs_dir)
        library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
        return WorkerService(
            store=stress_store,
            queue=stress_queue,
            jobs_dir=stress_jobs_dir,
            runner=runner,
            state_machine=stress_state_machine,
            retry=WorkerRetryPolicy(
                max_attempts=1,
                backoff_base_seconds=0.0,
                backoff_max_seconds=0.0,
            ),
            do_file_generator=DoFileGenerator(
                do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir)
            ),
            sleep=lambda _seconds: None,
        )

    return _factory


@pytest.fixture
def stress_app(
    stress_job_service: JobService,
    stress_draft_service: DraftService,
    stress_artifacts_service: ArtifactsService,
    stress_store: JobStore,
    stress_jobs_dir: Path,
) -> Iterator[FastAPI]:
    app = create_app()
    library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
    app.dependency_overrides[deps.get_job_service] = lambda: stress_job_service
    app.dependency_overrides[deps.get_job_query_service] = lambda: JobQueryService(
        store=stress_store
    )
    app.dependency_overrides[deps.get_draft_service] = lambda: stress_draft_service
    app.dependency_overrides[deps.get_artifacts_service] = lambda: stress_artifacts_service
    app.dependency_overrides[deps.get_plan_service] = lambda: PlanService(
        store=stress_store,
        workspace=FileJobWorkspaceStore(jobs_dir=stress_jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir),
    )
    yield app


@pytest.fixture
def stress_client(stress_app: FastAPI) -> Iterator[TestClient]:
    with TestClient(stress_app) as client:
        yield client
