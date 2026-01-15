from __future__ import annotations

from collections.abc import AsyncIterator, Callable, Iterator
from datetime import datetime, timezone
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.do_file_generator import DoFileGenerator
from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.output_formatter_service import OutputFormatterService
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.domain.task_code_redeem_service import TaskCodeRedeemService
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.main import create_app
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_llm_client import FakeLLMClient
from tests.fakes.fake_stata_runner import FakeStataRunner


@pytest.fixture
def e2e_jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def e2e_queue_dir(tmp_path: Path) -> Path:
    return tmp_path / "queue"


@pytest.fixture
def e2e_do_template_library_dir() -> Path:
    return Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"


@pytest.fixture
def e2e_store(e2e_jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=e2e_jobs_dir)


@pytest.fixture
def e2e_state_machine() -> JobStateMachine:
    return JobStateMachine()


@pytest.fixture
def e2e_idempotency() -> JobIdempotency:
    return JobIdempotency()


@pytest.fixture
def e2e_queue(e2e_queue_dir: Path) -> FileWorkerQueue:
    return FileWorkerQueue(queue_dir=e2e_queue_dir, lease_ttl_seconds=60)


@pytest.fixture
def e2e_llm(e2e_jobs_dir: Path) -> TracedLLMClient:
    return TracedLLMClient(
        inner=FakeLLMClient(),
        jobs_dir=e2e_jobs_dir,
        model="fake",
        temperature=0.0,
        seed=None,
        timeout_seconds=0.2,
        max_attempts=1,
        retry_backoff_base_seconds=0.0,
        retry_backoff_max_seconds=0.0,
    )


@pytest.fixture
def e2e_job_workspace_store(e2e_jobs_dir: Path) -> FileJobWorkspaceStore:
    return FileJobWorkspaceStore(jobs_dir=e2e_jobs_dir)


@pytest.fixture
def e2e_plan_service(
    e2e_store: JobStore,
    e2e_job_workspace_store: FileJobWorkspaceStore,
    e2e_do_template_library_dir: Path,
) -> PlanService:
    return PlanService(
        store=e2e_store,
        workspace=e2e_job_workspace_store,
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=e2e_do_template_library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=e2e_do_template_library_dir),
        llm=None,
    )


@pytest.fixture
def e2e_job_service(
    e2e_store: JobStore,
    e2e_queue: FileWorkerQueue,
    e2e_plan_service: PlanService,
    e2e_state_machine: JobStateMachine,
    e2e_idempotency: JobIdempotency,
) -> JobService:
    return JobService(
        store=e2e_store,
        scheduler=QueueJobScheduler(queue=e2e_queue),
        plan_service=e2e_plan_service,
        state_machine=e2e_state_machine,
        idempotency=e2e_idempotency,
    )


@pytest.fixture
def e2e_draft_service(
    e2e_store: JobStore,
    e2e_llm: TracedLLMClient,
    e2e_state_machine: JobStateMachine,
    e2e_job_workspace_store: FileJobWorkspaceStore,
    e2e_do_template_library_dir: Path,
) -> DraftService:
    selection = DoTemplateSelectionService(
        store=e2e_store,
        llm=e2e_llm,
        catalog=FileSystemDoTemplateCatalog(library_dir=e2e_do_template_library_dir),
    )
    return DraftService(
        store=e2e_store,
        llm=e2e_llm,
        state_machine=e2e_state_machine,
        workspace=e2e_job_workspace_store,
        do_template_selection=selection,
    )


@pytest.fixture
def e2e_job_inputs_service(
    e2e_store: JobStore,
    e2e_job_workspace_store: FileJobWorkspaceStore,
) -> JobInputsService:
    return JobInputsService(store=e2e_store, workspace=e2e_job_workspace_store)


@pytest.fixture
def e2e_job_query_service(e2e_store: JobStore) -> JobQueryService:
    return JobQueryService(store=e2e_store)


@pytest.fixture
def e2e_artifacts_service(e2e_store: JobStore, e2e_jobs_dir: Path) -> ArtifactsService:
    return ArtifactsService(store=e2e_store, jobs_dir=e2e_jobs_dir)


@pytest.fixture
def e2e_task_code_redeem_service(e2e_store: JobStore) -> TaskCodeRedeemService:
    return TaskCodeRedeemService(
        store=e2e_store,
        now=lambda: datetime(2099, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
        task_codes=None,
    )


@pytest.fixture
def e2e_app(
    e2e_store: JobStore,
    e2e_job_service: JobService,
    e2e_job_inputs_service: JobInputsService,
    e2e_job_query_service: JobQueryService,
    e2e_draft_service: DraftService,
    e2e_artifacts_service: ArtifactsService,
    e2e_plan_service: PlanService,
    e2e_task_code_redeem_service: TaskCodeRedeemService,
    e2e_job_workspace_store: FileJobWorkspaceStore,
) -> Iterator[FastAPI]:
    app = create_app()
    app.dependency_overrides[deps.get_job_store] = async_override(e2e_store)
    app.dependency_overrides[deps.get_job_service] = async_override(e2e_job_service)
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(
        e2e_job_inputs_service
    )
    app.dependency_overrides[deps.get_job_workspace_store] = async_override(e2e_job_workspace_store)
    app.dependency_overrides[deps.get_job_query_service] = async_override(e2e_job_query_service)
    app.dependency_overrides[deps.get_draft_service] = async_override(e2e_draft_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(e2e_artifacts_service)
    app.dependency_overrides[deps.get_plan_service] = async_override(e2e_plan_service)
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(
        e2e_task_code_redeem_service
    )
    yield app


@pytest.fixture
async def e2e_client(e2e_app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    async with asgi_client(app=e2e_app) as client:
        yield client


@pytest.fixture
def e2e_worker_service_factory(
    e2e_store: JobStore,
    e2e_queue: FileWorkerQueue,
    e2e_jobs_dir: Path,
    e2e_state_machine: JobStateMachine,
    e2e_do_template_library_dir: Path,
) -> Callable[..., WorkerService]:
    def _make(*, scripted_ok: list[bool] | None = None) -> WorkerService:
        runner = FakeStataRunner(jobs_dir=e2e_jobs_dir, scripted_ok=scripted_ok)
        return WorkerService(
            store=e2e_store,
            queue=e2e_queue,
            jobs_dir=e2e_jobs_dir,
            runner=runner,
            output_formatter=OutputFormatterService(jobs_dir=e2e_jobs_dir),
            state_machine=e2e_state_machine,
            retry=WorkerRetryPolicy(
                max_attempts=3,
                backoff_base_seconds=0.0,
                backoff_max_seconds=0.0,
            ),
            do_file_generator=DoFileGenerator(
                do_template_repo=FileSystemDoTemplateRepository(
                    library_dir=e2e_do_template_library_dir
                )
            ),
            sleep=lambda _seconds: None,
        )

    return _make
