from __future__ import annotations

import asyncio

import pytest

from src.domain.audit import AuditContext, AuditEvent, AuditLogger
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.models import JobStatus
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobIllegalTransitionError, JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.utils.job_workspace import resolve_job_dir


class InMemoryAuditLogger(AuditLogger):
    def __init__(self) -> None:
        self.events: list[AuditEvent] = []

    def emit(self, *, event: AuditEvent) -> None:
        self.events.append(event)


def test_confirm_job_emits_audit_events(store, draft_service, jobs_dir) -> None:
    # Arrange
    audit = InMemoryAuditLogger()
    ctx = AuditContext.user(
        actor_id="user-1",
        request_id="req-1",
        ip="127.0.0.1",
        user_agent="pytest",
        source="api",
    )
    job_service = JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        plan_service=PlanService(store=store, workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir)),
        state_machine=JobStateMachine(),
        idempotency=JobIdempotency(),
        audit=audit,
        audit_context=ctx,
    )
    job = job_service.create_job(requirement=None)
    asyncio.run(draft_service.preview(job_id=job.job_id))

    # Act
    job_service.confirm_job(job_id=job.job_id, confirmed=True)

    # Assert
    actions = [event.action for event in audit.events]
    assert "job.confirm" in actions
    assert "job.run.trigger" in actions
    confirm_event = next(event for event in audit.events if event.action == "job.confirm")
    assert confirm_event.context.actor.actor_id == "user-1"
    assert confirm_event.context.request_id == "req-1"


def test_create_job_writes_job_json(job_service, store, jobs_dir):
    job = job_service.create_job(requirement="hello", inputs_fingerprint="fp_1")
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    path = job_dir / "job.json"
    assert path.exists()
    loaded = store.load(job.job_id)
    assert loaded.job_id == job.job_id
    assert loaded.trace_id is not None
    assert len(loaded.trace_id) == 32
    assert loaded.status == JobStatus.CREATED


def test_create_job_with_same_fingerprint_and_normalized_requirement_is_idempotent(job_service):
    job_1 = job_service.create_job(requirement=" hello   world ", inputs_fingerprint="fp_1")
    job_2 = job_service.create_job(requirement="hello\nworld", inputs_fingerprint="fp_1")
    assert job_1.job_id == job_2.job_id
    assert job_2.status == JobStatus.CREATED


def test_create_job_with_different_plan_revision_creates_different_job(job_service):
    job_1 = job_service.create_job(
        requirement="hello",
        inputs_fingerprint="fp_1",
        plan_revision=1,
    )
    job_2 = job_service.create_job(
        requirement="hello",
        inputs_fingerprint="fp_1",
        plan_revision=2,
    )
    assert job_1.job_id != job_2.job_id


def test_confirm_job_with_created_status_raises_job_illegal_transition_error(job_service):
    job = job_service.create_job(requirement=None)
    with pytest.raises(JobIllegalTransitionError) as exc_info:
        job_service.confirm_job(job_id=job.job_id, confirmed=True)
    assert exc_info.value.error_code == "JOB_ILLEGAL_TRANSITION"


def test_confirm_job_after_draft_preview_sets_queued(job_service, draft_service, store):
    job = job_service.create_job(requirement=None)
    asyncio.run(draft_service.preview(job_id=job.job_id))

    updated = job_service.confirm_job(job_id=job.job_id, confirmed=True)
    assert updated.status == JobStatus.QUEUED
    assert updated.scheduled_at is not None

    loaded = store.load(job.job_id)
    assert loaded.status == JobStatus.QUEUED


def test_confirm_job_when_already_queued_is_idempotent(job_service, draft_service):
    job = job_service.create_job(requirement=None)
    asyncio.run(draft_service.preview(job_id=job.job_id))

    first = job_service.confirm_job(job_id=job.job_id, confirmed=True)
    second = job_service.confirm_job(job_id=job.job_id, confirmed=True)
    assert second.status == JobStatus.QUEUED
    assert second.scheduled_at == first.scheduled_at
