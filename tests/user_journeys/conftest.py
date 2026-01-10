from __future__ import annotations

import json
from collections.abc import AsyncIterator, Callable, Iterator
from datetime import datetime, timezone
from pathlib import Path

import httpx
import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from src.api import deps
from src.domain.artifacts_service import ArtifactsService
from src.domain.do_file_generator import DoFileGenerator
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.models import JobInputs
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
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override
from tests.fakes.fake_llm_client import FakeLLMClient
from tests.fakes.fake_stata_runner import FakeStataRunner


@pytest.fixture
def journey_jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def journey_queue_dir(tmp_path: Path) -> Path:
    return tmp_path / "queue"


@pytest.fixture
def journey_store(journey_jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=journey_jobs_dir)


@pytest.fixture
def journey_state_machine() -> JobStateMachine:
    return JobStateMachine()


@pytest.fixture
def journey_idempotency() -> JobIdempotency:
    return JobIdempotency()


@pytest.fixture
def journey_queue(journey_queue_dir: Path) -> FileWorkerQueue:
    return FileWorkerQueue(queue_dir=journey_queue_dir, lease_ttl_seconds=60)


@pytest.fixture
def journey_job_service(
    journey_store: JobStore,
    journey_state_machine: JobStateMachine,
    journey_idempotency: JobIdempotency,
    journey_queue: FileWorkerQueue,
    journey_jobs_dir: Path,
) -> JobService:
    scheduler = QueueJobScheduler(queue=journey_queue)
    library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
    plan_service = PlanService(
        store=journey_store,
        workspace=FileJobWorkspaceStore(jobs_dir=journey_jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir),
    )
    return JobService(
        store=journey_store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=journey_state_machine,
        idempotency=journey_idempotency,
    )


@pytest.fixture
def journey_draft_service(
    journey_store: JobStore,
    journey_state_machine: JobStateMachine,
    journey_jobs_dir: Path,
) -> DraftService:
    llm = TracedLLMClient(
        inner=FakeLLMClient(),
        jobs_dir=journey_jobs_dir,
        model="fake",
        temperature=0.0,
        seed=None,
        timeout_seconds=30.0,
        max_attempts=3,
        retry_backoff_base_seconds=1.0,
        retry_backoff_max_seconds=30.0,
    )
    return DraftService(
        store=journey_store,
        llm=llm,
        state_machine=journey_state_machine,
        workspace=FileJobWorkspaceStore(jobs_dir=journey_jobs_dir),
    )


@pytest.fixture
def journey_artifacts_service(journey_store: JobStore, journey_jobs_dir: Path) -> ArtifactsService:
    return ArtifactsService(store=journey_store, jobs_dir=journey_jobs_dir)


@pytest.fixture
def journey_worker_service(
    journey_store: JobStore,
    journey_queue: FileWorkerQueue,
    journey_jobs_dir: Path,
    journey_state_machine: JobStateMachine,
) -> WorkerService:
    runner = FakeStataRunner(jobs_dir=journey_jobs_dir)
    library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
    return WorkerService(
        store=journey_store,
        queue=journey_queue,
        jobs_dir=journey_jobs_dir,
        runner=runner,
        state_machine=journey_state_machine,
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(
            do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir)
        ),
        sleep=lambda _seconds: None,
    )


@pytest.fixture
def journey_plan_service(journey_store: JobStore, journey_jobs_dir: Path) -> PlanService:
    library_dir = Path(__file__).resolve().parents[2] / "assets" / "stata_do_library"
    return PlanService(
        store=journey_store,
        workspace=FileJobWorkspaceStore(jobs_dir=journey_jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir),
    )


@pytest.fixture
def journey_job_query_service(journey_store: JobStore) -> JobQueryService:
    return JobQueryService(store=journey_store)


@pytest.fixture
def journey_job_inputs_service(journey_store: JobStore, journey_jobs_dir: Path) -> JobInputsService:
    return JobInputsService(
        store=journey_store,
        workspace=FileJobWorkspaceStore(jobs_dir=journey_jobs_dir),
    )


@pytest.fixture
def journey_task_code_redeem_service(journey_store: JobStore) -> TaskCodeRedeemService:
    return TaskCodeRedeemService(
        store=journey_store,
        now=lambda: datetime(2099, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
    )


@pytest.fixture
def journey_attach_sample_inputs(
    journey_store: JobStore,
    journey_jobs_dir: Path,
) -> Callable[[str], None]:
    def _attach(job_id: str) -> None:
        job = journey_store.load(job_id)
        job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
        journey_store.save(job)

        job_dir = resolve_job_dir(jobs_dir=journey_jobs_dir, job_id=job_id)
        assert job_dir is not None
        inputs_dir = job_dir / "inputs"
        inputs_dir.mkdir(parents=True, exist_ok=True)
        (inputs_dir / "primary.csv").write_text("id,y,x\n1,1,2\n", encoding="utf-8")
        (inputs_dir / "manifest.json").write_text(
            json.dumps(
                {
                    "schema_version": 2,
                    "datasets": [
                        {
                            "dataset_key": "primary",
                            "role": "primary_dataset",
                            "rel_path": "inputs/primary.csv",
                            "format": "csv",
                            "original_name": "primary.csv",
                        }
                    ],
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )

    return _attach


@pytest.fixture
def journey_app(
    journey_job_service: JobService,
    journey_draft_service: DraftService,
    journey_artifacts_service: ArtifactsService,
    journey_plan_service: PlanService,
    journey_job_query_service: JobQueryService,
    journey_job_inputs_service: JobInputsService,
    journey_task_code_redeem_service: TaskCodeRedeemService,
    journey_store: JobStore,
) -> Iterator[FastAPI]:
    app = create_app()
    app.dependency_overrides[deps.get_job_store] = async_override(journey_store)
    app.dependency_overrides[deps.get_job_service] = async_override(journey_job_service)
    app.dependency_overrides[deps.get_job_inputs_service] = async_override(
        journey_job_inputs_service
    )
    app.dependency_overrides[deps.get_job_query_service] = async_override(journey_job_query_service)
    app.dependency_overrides[deps.get_draft_service] = async_override(journey_draft_service)
    app.dependency_overrides[deps.get_artifacts_service] = async_override(journey_artifacts_service)
    app.dependency_overrides[deps.get_plan_service] = async_override(journey_plan_service)
    app.dependency_overrides[deps.get_task_code_redeem_service] = async_override(
        journey_task_code_redeem_service
    )
    yield app


@pytest.fixture
async def journey_client(journey_app: FastAPI) -> AsyncIterator[httpx.AsyncClient]:
    async with asgi_client(app=journey_app) as client:
        yield client


@pytest.fixture
def journey_test_client(journey_app: FastAPI) -> Iterator[TestClient]:
    with TestClient(journey_app) as client:
        yield client
