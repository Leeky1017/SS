from __future__ import annotations

import json
from pathlib import Path

from src.domain.do_file_generator import DEFAULT_SUMMARY_TABLE_FILENAME
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.models import ArtifactKind, JobConfirmation, JobInputs, JobStatus
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.fake_stata_runner import FakeStataRunner
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.infra.stata_run_support import ERROR_FILENAME, META_FILENAME
from src.utils.job_workspace import resolve_job_dir


def _write_job_inputs(*, jobs_dir: Path, job_id: str) -> None:
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    inputs_dir = job_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    dataset_rel_path = "inputs/primary.csv"
    (inputs_dir / "primary.csv").write_text("id,y,x\n1,1,2\n", encoding="utf-8")
    (inputs_dir / "manifest.json").write_text(
        json.dumps({"primary_dataset": {"rel_path": dataset_rel_path}}, indent=2, sort_keys=True)
        + "\n",
        encoding="utf-8",
    )


def _prepare_queued_job(*, jobs_dir: Path, queue: FileWorkerQueue) -> str:
    store = JobStore(jobs_dir=jobs_dir)
    state_machine = JobStateMachine()
    scheduler = QueueJobScheduler(queue=queue)
    plan_service = PlanService(store=store)
    job_service = JobService(
        store=store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=state_machine,
        idempotency=JobIdempotency(),
    )

    job = job_service.create_job(requirement="hello")
    job.status = JobStatus.DRAFT_READY
    job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    store.save(job)
    _write_job_inputs(jobs_dir=jobs_dir, job_id=job.job_id)
    plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(requirement="hello"))
    job_service.trigger_run(job_id=job.job_id)
    return job.job_id


def _noop_sleep(_seconds: float) -> None:
    return None


def test_worker_service_with_success_once_marks_job_succeeded(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)

    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[True]),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=_noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    assert len(job.runs) == 1
    assert job.runs[0].status == "succeeded"
    assert any(ref.kind == ArtifactKind.RUN_META_JSON for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.STATA_EXPORT_TABLE for ref in job.artifacts_index)
    run_id = job.runs[0].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    assert (job_dir / "runs" / run_id / "artifacts" / META_FILENAME).exists()
    assert (job_dir / "runs" / run_id / "artifacts" / DEFAULT_SUMMARY_TABLE_FILENAME).exists()
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_trigger_run_writes_queue_record_with_traceparent_matching_job_trace_id(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)

    # Act
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)

    # Assert
    queued_files = list((queue_dir / "queued").glob("*.json"))
    assert len(queued_files) == 1
    record = json.loads(queued_files[0].read_text(encoding="utf-8"))
    traceparent = record.get("traceparent")
    assert isinstance(traceparent, str)
    parts = traceparent.split("-")
    assert len(parts) == 4
    trace_id = parts[1]
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.trace_id == trace_id


def test_worker_service_with_failure_then_success_retries_and_succeeds(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)

    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[False, True]),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=_noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    assert len(job.runs) == 2
    assert job.runs[0].status == "failed"
    assert job.runs[1].status == "succeeded"
    assert job.runs[0].run_id != job.runs[1].run_id
    run_ids = {attempt.run_id for attempt in job.runs}
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    assert len(list((job_dir / "runs").iterdir())) == len(run_ids)
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_worker_service_with_failures_until_max_marks_job_failed(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)

    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[False, False]),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=2, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=_noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.FAILED
    assert len(job.runs) == 2
    assert job.runs[0].status == "failed"
    assert job.runs[1].status == "failed"
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    for attempt in job.runs:
        assert (job_dir / "runs" / attempt.run_id / "artifacts" / META_FILENAME).exists()
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_worker_service_when_plan_missing_persists_error_artifacts_and_marks_job_failed(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    store = JobStore(jobs_dir=jobs_dir)
    scheduler = QueueJobScheduler(queue=queue)
    job_service = JobService(
        store=store,
        scheduler=scheduler,
        state_machine=JobStateMachine(),
        idempotency=JobIdempotency(),
    )
    job = job_service.create_job(requirement="hello")
    job.status = JobStatus.DRAFT_READY
    store.save(job)
    job_service.trigger_run(job_id=job.job_id)

    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=_noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    reloaded = store.load(job.job_id)
    assert reloaded.status == JobStatus.FAILED
    assert len(reloaded.runs) == 1
    run_id = reloaded.runs[0].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    error_path = job_dir / "runs" / run_id / "artifacts" / ERROR_FILENAME
    payload = json.loads(error_path.read_text(encoding="utf-8"))
    assert payload["error_code"] == "PLAN_MISSING"


def test_worker_service_when_inputs_manifest_missing_persists_error_artifacts_and_marks_job_failed(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    job_id = _prepare_queued_job(jobs_dir=jobs_dir, queue=queue)
    store = JobStore(jobs_dir=jobs_dir)
    job = store.load(job_id)
    job.inputs = None
    store.save(job)

    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=_noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    reloaded = store.load(job_id)
    assert reloaded.status == JobStatus.FAILED
    assert len(reloaded.runs) == 1
    run_id = reloaded.runs[0].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    error_path = job_dir / "runs" / run_id / "artifacts" / ERROR_FILENAME
    payload = json.loads(error_path.read_text(encoding="utf-8"))
    assert payload["error_code"] == "INPUTS_MANIFEST_MISSING"
