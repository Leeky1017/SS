from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any

from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job, JobStatus
from src.domain.state_machine import JobStateMachine
from src.domain.worker_claim_handling import ensure_job_claimable, load_job_or_handle
from src.domain.worker_queue import QueueClaim
from src.infra.exceptions import JobDataCorruptedError, JobNotFoundError, JobStoreIOError


@dataclass
class _FakeStore:
    job: Job | None = None
    load_error: Exception | None = None
    saved: list[tuple[str, Job]] | None = None

    def load(self, *, tenant_id: str, job_id: str) -> Job:
        if self.load_error is not None:
            raise self.load_error
        assert self.job is not None
        assert self.job.job_id == job_id
        return self.job

    def save(self, *, tenant_id: str, job: Job) -> None:
        if self.saved is None:
            self.saved = []
        self.saved.append((tenant_id, job))


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


def _job(*, job_id: str = "job_123", status: JobStatus) -> Job:
    return Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id="default",
        job_id=job_id,
        status=status,
        created_at="2026-01-01T00:00:00Z",
    )


def test_load_job_or_handle_when_job_missing_acks_and_returns_none() -> None:
    store = _FakeStore(load_error=JobNotFoundError(job_id="job_123"))
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    job = load_job_or_handle(
        store=store,
        claim=_claim(),
        ack=acked.append,
        release=released.append,
    )

    assert job is None
    assert len(acked) == 1
    assert released == []


def test_load_job_or_handle_when_job_corrupted_acks_and_returns_none() -> None:
    store = _FakeStore(load_error=JobDataCorruptedError(job_id="job_123"))
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    job = load_job_or_handle(
        store=store,
        claim=_claim(),
        ack=acked.append,
        release=released.append,
    )

    assert job is None
    assert len(acked) == 1
    assert released == []


def test_load_job_or_handle_when_store_io_error_releases_and_returns_none() -> None:
    store = _FakeStore(load_error=JobStoreIOError(operation="load", job_id="job_123"))
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    job = load_job_or_handle(
        store=store,
        claim=_claim(),
        ack=acked.append,
        release=released.append,
    )

    assert job is None
    assert acked == []
    assert len(released) == 1


def test_load_job_or_handle_when_load_succeeds_returns_job() -> None:
    job_in_store = _job(status=JobStatus.QUEUED)
    store = _FakeStore(job=job_in_store)
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    job = load_job_or_handle(
        store=store,
        claim=_claim(),
        ack=acked.append,
        release=released.append,
    )

    assert job is job_in_store
    assert acked == []
    assert released == []


def test_ensure_job_claimable_when_queued_transitions_to_running_and_emits_audit() -> None:
    job = _job(status=JobStatus.QUEUED)
    store = _FakeStore(job=job)
    claim = _claim()
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []
    audits: list[dict[str, Any]] = []

    ok = ensure_job_claimable(
        store=store,
        state_machine=JobStateMachine(),
        job=job,
        claim=claim,
        ack=acked.append,
        release=released.append,
        emit_audit=lambda **kwargs: audits.append(kwargs),
    )

    assert ok is True
    assert job.status == JobStatus.RUNNING
    assert acked == []
    assert released == []
    assert store.saved is not None and len(store.saved) == 1
    assert len(audits) == 1
    assert audits[0]["action"] == "job.status.transition"


def test_ensure_job_claimable_when_job_already_done_acks_and_returns_false() -> None:
    job = _job(status=JobStatus.SUCCEEDED)
    store = _FakeStore(job=job)
    claim = _claim()
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    ok = ensure_job_claimable(
        store=store,
        state_machine=JobStateMachine(),
        job=job,
        claim=claim,
        ack=acked.append,
        release=released.append,
        emit_audit=lambda **_kwargs: None,
    )

    assert ok is False
    assert len(acked) == 1
    assert released == []


def test_ensure_job_claimable_when_not_ready_releases_and_returns_false() -> None:
    job = _job(status=JobStatus.CONFIRMED)
    store = _FakeStore(job=job)
    claim = _claim()
    acked: list[QueueClaim] = []
    released: list[QueueClaim] = []

    ok = ensure_job_claimable(
        store=store,
        state_machine=JobStateMachine(),
        job=job,
        claim=claim,
        ack=acked.append,
        release=released.append,
        emit_audit=lambda **_kwargs: None,
    )

    assert ok is False
    assert acked == []
    assert len(released) == 1
