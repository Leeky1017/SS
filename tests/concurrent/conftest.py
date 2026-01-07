from __future__ import annotations

from collections.abc import Callable
from pathlib import Path

import pytest

from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.models import JobConfirmation, JobStatus
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler


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
def plan_service(store: JobStore) -> PlanService:
    return PlanService(store=store)


@pytest.fixture
def noop_sleep() -> Callable[[float], None]:
    def _noop(_seconds: float) -> None:
        return None

    return _noop


@pytest.fixture
def create_queued_job(
    store: JobStore,
    job_service: JobService,
    plan_service: PlanService,
) -> Callable[[str], str]:
    def _create(requirement: str) -> str:
        job = job_service.create_job(requirement=requirement)
        job.status = JobStatus.DRAFT_READY
        store.save(job)
        plan_service.freeze_plan(
            job_id=job.job_id,
            confirmation=JobConfirmation(requirement=requirement),
        )
        job_service.trigger_run(job_id=job.job_id)
        return job.job_id

    return _create
