from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path

import pytest

from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.models import JobConfirmation, JobInputs, JobStatus
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.utils.job_workspace import resolve_job_dir


@pytest.fixture
def jobs_dir(tmp_path: Path) -> Path:
    return tmp_path / "jobs"


@pytest.fixture
def queue_dir(tmp_path: Path) -> Path:
    return tmp_path / "queue"


@pytest.fixture
def store(jobs_dir: Path) -> JobStore:
    return JobStore(jobs_dir=jobs_dir)


@pytest.fixture
def queue(queue_dir: Path) -> FileWorkerQueue:
    return FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)


@pytest.fixture
def state_machine() -> JobStateMachine:
    return JobStateMachine()


@pytest.fixture
def job_service(
    store: JobStore,
    queue: FileWorkerQueue,
    state_machine: JobStateMachine,
    plan_service: PlanService,
) -> JobService:
    scheduler = QueueJobScheduler(queue=queue)
    return JobService(
        store=store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=state_machine,
        idempotency=JobIdempotency(),
    )


@pytest.fixture
def plan_service(store: JobStore, jobs_dir: Path) -> PlanService:
    return PlanService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))


@pytest.fixture
def noop_sleep() -> Callable[[float], None]:
    def _noop(_seconds: float) -> None:
        return None

    return _noop


@pytest.fixture
def create_queued_job(
    jobs_dir: Path,
    store: JobStore,
    job_service: JobService,
    plan_service: PlanService,
) -> Callable[[str], str]:
    def _create(requirement: str) -> str:
        job = job_service.create_job(requirement=requirement)
        job.status = JobStatus.DRAFT_READY
        job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
        store.save(job)
        job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
        assert job_dir is not None
        (job_dir / "inputs").mkdir(parents=True, exist_ok=True)
        (job_dir / "inputs" / "primary.csv").write_text("id,y,x\n1,1,2\n", encoding="utf-8")
        (job_dir / "inputs" / "manifest.json").write_text(
            json.dumps(
                {"primary_dataset": {"rel_path": "inputs/primary.csv"}},
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
        plan_service.freeze_plan(
            job_id=job.job_id,
            confirmation=JobConfirmation(requirement=requirement),
        )
        job_service.trigger_run(job_id=job.job_id)
        return job.job_id

    return _create
