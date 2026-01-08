from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta, timezone
from pathlib import Path

from fastapi.testclient import TestClient

from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.models import JobConfirmation, JobInputs, JobStatus
from src.domain.plan_service import PlanService
from src.domain.stata_runner import RunResult
from src.domain.state_machine import JobStateMachine
from src.domain.worker_plan_executor import execute_plan
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir


def _prepare_queued_job(*, jobs_dir: Path, queue: FileWorkerQueue) -> str:
    store = JobStore(jobs_dir=jobs_dir)
    state_machine = JobStateMachine()
    scheduler = QueueJobScheduler(queue=queue)
    plan_service = PlanService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))
    job_service = JobService(
        store=store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=state_machine,
        idempotency=JobIdempotency(),
    )

    job = job_service.create_job(requirement="hello")
    job.status = JobStatus.DRAFT_READY
    store.save(job)
    plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(requirement="hello"))
    job_service.trigger_run(job_id=job.job_id)
    return job.job_id


def test_create_app_lifespan_emits_startup_and_shutdown_events(caplog) -> None:
    caplog.set_level(logging.INFO)
    app = create_app()

    with TestClient(app):
        pass

    messages = [record.getMessage() for record in caplog.records]
    assert "SS_API_STARTUP" in messages
    assert "SS_API_SHUTDOWN_INITIATED" in messages
    assert "SS_API_SHUTDOWN_COMPLETE" in messages


def test_api_shutdown_gate_when_shutting_down_returns_503() -> None:
    app = create_app()

    with TestClient(app) as client:
        app.state.shutting_down = True
        response = client.get("/v1/jobs/job-any")

    assert response.status_code == 503
    assert response.json()["error_code"] == "SERVICE_SHUTTING_DOWN"


def test_worker_service_when_shutdown_requested_after_claim_releases_claim_and_skips_processing(
    tmp_path: Path,
) -> None:
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)

    class _StopAfterClaim:
        def __init__(self) -> None:
            self._calls = 0

        def __call__(self) -> bool:
            self._calls += 1
            return self._calls >= 2

    stop = _StopAfterClaim()
    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=_CapturingRunner(),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
    )

    processed = service.process_next(
        worker_id="worker-1",
        stop_requested=stop,
        shutdown_deadline=lambda: None,
    )

    assert processed is False
    assert list((queue_dir / "queued").glob("*.json")) == [queue_dir / "queued" / f"{job_id}.json"]
    assert list((queue_dir / "claimed").glob("*.json")) == []
    assert JobStore(jobs_dir=jobs_dir).load(job_id).status == JobStatus.QUEUED


def test_execute_plan_with_shutdown_deadline_caps_timeout_seconds(tmp_path: Path) -> None:
    now = datetime(2026, 1, 1, tzinfo=timezone.utc)
    deadline = now + timedelta(seconds=10)

    runner = _CapturingRunner()
    jobs_dir = tmp_path / "jobs"
    store = JobStore(jobs_dir=jobs_dir)
    plan_service = PlanService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir))
    job_service = JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        plan_service=plan_service,
        state_machine=JobStateMachine(),
        idempotency=JobIdempotency(),
    )

    job = job_service.create_job(requirement="hello")
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
    plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(requirement="hello"))
    job = store.load(job.job_id)
    result = execute_plan(
        job=job,
        run_id="run-1",
        jobs_dir=jobs_dir,
        runner=runner,
        shutdown_deadline=deadline,
        clock=lambda: now,
    )

    assert result.ok is True
    assert runner.timeout_seconds == 10


class _CapturingRunner:
    def __init__(self) -> None:
        self.timeout_seconds: int | None = None

    def run(
        self,
        *,
        tenant_id: str = "default",
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ) -> RunResult:
        self.timeout_seconds = timeout_seconds
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=tuple(),
            error=None,
        )
