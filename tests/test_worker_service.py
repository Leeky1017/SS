from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from pathlib import Path

import pytest

from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job, JobStatus, RunAttempt
from src.domain.output_formatter_service import OutputFormatterOutcome
from src.domain.stata_runner import RunError, RunResult
from src.domain.state_machine import JobStateMachine
from src.domain.worker_queue import QueueClaim
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.exceptions import JobNotFoundError, QueueIOError


@dataclass
class _FakeQueue:
    claim_result: QueueClaim | None = None
    acked: list[QueueClaim] | None = None
    released: list[QueueClaim] | None = None
    ack_error: Exception | None = None
    release_error: Exception | None = None

    def claim(self, *, worker_id: str) -> QueueClaim | None:
        return self.claim_result

    def ack(self, *, claim: QueueClaim) -> None:
        if self.ack_error is not None:
            raise self.ack_error
        if self.acked is None:
            self.acked = []
        self.acked.append(claim)

    def release(self, *, claim: QueueClaim) -> None:
        if self.release_error is not None:
            raise self.release_error
        if self.released is None:
            self.released = []
        self.released.append(claim)

    def enqueue(
        self,
        job_id: str,
        *,
        tenant_id: str = "default",
        traceparent: str | None = None,
    ) -> None:
        raise NotImplementedError


@dataclass
class _FakeStore:
    job: Job | None = None
    load_error: Exception | None = None
    saves: int = 0

    def load(self, job_id: str, *, tenant_id: str = "default") -> Job:
        if self.load_error is not None:
            raise self.load_error
        assert self.job is not None
        return self.job

    def save(self, job: Job, *, tenant_id: str = "default") -> None:
        self.saves += 1
        self.job = job

    def create(self, job: Job, *, tenant_id: str = "default") -> None:
        raise NotImplementedError

    def write_draft(self, *, job_id: str, draft: object, tenant_id: str = "default") -> None:
        raise NotImplementedError

    def write_artifact_json(
        self,
        *,
        job_id: str,
        rel_path: str,
        payload: object,
        tenant_id: str = "default",
    ) -> None:
        raise NotImplementedError


@dataclass
class _FakeOutputFormatter:
    outcome: OutputFormatterOutcome

    def format_run_outputs(
        self,
        *,
        job: Job,
        run_id: str,
        artifacts: tuple[object, ...],
    ) -> OutputFormatterOutcome:
        return self.outcome


class _UnusedRunner:
    def run(self, *args: object, **kwargs: object) -> RunResult:
        raise AssertionError("runner should not be called in unit tests")


def _job(*, status: JobStatus, runs: int = 0) -> Job:
    job = Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id="default",
        job_id="job_123",
        status=status,
        created_at="2026-01-01T00:00:00Z",
        runs=[],
    )
    for i in range(runs):
        job.runs.append(
            RunAttempt(
                run_id=f"run_{i}",
                attempt=i + 1,
                status="failed",
                started_at=None,
                ended_at=None,
                artifacts=[],
            )
        )
    return job


def _claim(*, job_id: str = "job_123") -> QueueClaim:
    now = datetime.now(tz=timezone.utc)
    return QueueClaim(
        tenant_id="default",
        job_id=job_id,
        claim_id="claim_1",
        worker_id="worker_1",
        claimed_at=now,
        lease_expires_at=now + timedelta(seconds=30),
    )


def _service(
    *,
    store: _FakeStore,
    queue: _FakeQueue,
    jobs_dir: Path,
    output_formatter: _FakeOutputFormatter,
    retry: WorkerRetryPolicy,
    sleep: Callable[[float], None] | None = None,
) -> WorkerService:
    return WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=_UnusedRunner(),
        output_formatter=output_formatter,
        dependency_checker=None,
        state_machine=JobStateMachine(),
        retry=retry,
        do_file_generator=None,
        metrics=None,
        audit=None,
        clock=lambda: datetime(2026, 1, 1),
        sleep=(lambda _seconds: None) if sleep is None else sleep,
    )


def test_process_next_when_no_claim_returns_false(tmp_path: Path) -> None:
    queue = _FakeQueue(claim_result=None)
    store = _FakeStore()
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    assert svc.process_next(worker_id="worker_1") is False


def test_process_next_when_stop_requested_before_claim_returns_false(tmp_path: Path) -> None:
    queue = _FakeQueue(claim_result=_claim())
    store = _FakeStore(job=_job(status=JobStatus.RUNNING))
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    assert svc.process_next(worker_id="worker_1", stop_requested=lambda: True) is False
    assert queue.acked is None
    assert queue.released is None


def test_process_next_when_stop_requested_after_claim_releases_claim(tmp_path: Path) -> None:
    claim = _claim()
    queue = _FakeQueue(claim_result=claim)
    store = _FakeStore(job=_job(status=JobStatus.RUNNING))
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    stop_calls = {"n": 0}

    def _stop() -> bool:
        stop_calls["n"] += 1
        return stop_calls["n"] >= 2

    assert svc.process_next(worker_id="worker_1", stop_requested=_stop) is False
    assert queue.released is not None and queue.released == [claim]


def test_process_claim_when_job_not_found_acks_claim(tmp_path: Path) -> None:
    claim = _claim()
    queue = _FakeQueue()
    store = _FakeStore(load_error=JobNotFoundError(job_id=claim.job_id))
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    svc.process_claim(claim=claim)

    assert queue.acked is not None and queue.acked == [claim]
    assert queue.released is None


def test_run_job_with_retries_when_successful_finishes_and_acks(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    job = _job(status=JobStatus.QUEUED)
    claim = _claim()
    store = _FakeStore(job=job)
    queue = _FakeQueue()
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    def _fake_execute_plan(*, job: Job, run_id: str, **_kwargs: object) -> RunResult:
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=tuple(),
            error=None,
        )

    monkeypatch.setattr("src.domain.worker_service.execute_plan", _fake_execute_plan)

    svc.process_claim(claim=claim)

    assert store.job is not None and store.job.status == JobStatus.SUCCEEDED
    assert queue.acked is not None and queue.acked == [claim]


def test_run_job_with_retries_when_retriable_then_success_sleeps_and_succeeds(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    job = _job(status=JobStatus.RUNNING)
    claim = _claim()
    store = _FakeStore(job=job)
    queue = _FakeQueue()
    sleeps: list[float] = []

    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
        sleep=sleeps.append,
    )

    results: list[RunResult] = []

    def _fake_execute_plan(*, job: Job, run_id: str, **_kwargs: object) -> RunResult:
        if not results:
            results.append(
                RunResult(
                    job_id=job.job_id,
                    run_id=run_id,
                    ok=False,
                    exit_code=1,
                    timed_out=False,
                    artifacts=tuple(),
                    error=RunError(error_code="STATA_TIMEOUT", message="timeout"),
                )
            )
            return results[-1]
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=tuple(),
            error=None,
        )

    monkeypatch.setattr("src.domain.worker_service.execute_plan", _fake_execute_plan)

    svc.process_claim(claim=claim)

    assert sleeps == [1.0]
    assert store.job is not None and store.job.status == JobStatus.SUCCEEDED
    assert queue.acked is not None and queue.acked == [claim]


def test_run_job_with_retries_when_non_retriable_marks_failed_and_acks(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    job = _job(status=JobStatus.RUNNING)
    claim = _claim()
    store = _FakeStore(job=job)
    queue = _FakeQueue()
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    def _fake_execute_plan(*, job: Job, run_id: str, **_kwargs: object) -> RunResult:
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=False,
            exit_code=1,
            timed_out=False,
            artifacts=tuple(),
            error=RunError(error_code="PLAN_INVALID", message="invalid"),
        )

    monkeypatch.setattr("src.domain.worker_service.execute_plan", _fake_execute_plan)

    svc.process_claim(claim=claim)

    assert store.job is not None and store.job.status == JobStatus.FAILED
    assert queue.acked is not None and queue.acked == [claim]


def test_run_job_with_retries_when_output_formatter_errors_marks_failed(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    job = _job(status=JobStatus.RUNNING)
    claim = _claim()
    store = _FakeStore(job=job)
    queue = _FakeQueue()
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(
            outcome=OutputFormatterOutcome(
                artifacts=tuple(),
                error=RunError(error_code="OUTPUT_FORMATTER_FAILED", message="boom"),
            )
        ),
        retry=WorkerRetryPolicy(max_attempts=2, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    def _fake_execute_plan(*, job: Job, run_id: str, **_kwargs: object) -> RunResult:
        return RunResult(
            job_id=job.job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=tuple(),
            error=None,
        )

    monkeypatch.setattr("src.domain.worker_service.execute_plan", _fake_execute_plan)

    svc.process_claim(claim=claim)

    assert store.job is not None and store.job.status == JobStatus.FAILED
    assert queue.acked is not None and queue.acked == [claim]


def test_worker_ack_when_queue_fails_raises_queue_io_error(tmp_path: Path) -> None:
    claim = _claim()
    queue = _FakeQueue(ack_error=QueueIOError(operation="ack", path="/tmp/queue.json"))
    store = _FakeStore(job=_job(status=JobStatus.RUNNING))
    svc = _service(
        store=store,
        queue=queue,
        jobs_dir=tmp_path,
        output_formatter=_FakeOutputFormatter(outcome=OutputFormatterOutcome(artifacts=tuple())),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=1.0, backoff_max_seconds=30.0),
    )

    with pytest.raises(QueueIOError):
        svc._ack(claim)
