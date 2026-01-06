from __future__ import annotations

import asyncio
import json

import pytest

from src.domain.models import ArtifactKind, JobConfirmation
from src.infra.exceptions import PlanAlreadyFrozenError, PlanFreezeNotAllowedError


def test_freeze_plan_when_job_not_ready_raises_plan_freeze_not_allowed_error(
    job_service,
    plan_service,
):
    job = job_service.create_job(requirement="need a descriptive analysis")
    with pytest.raises(PlanFreezeNotAllowedError):
        plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())


def test_freeze_plan_persists_llm_plan_and_plan_artifact(
    job_service,
    draft_service,
    plan_service,
    store,
    jobs_dir,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))

    # Act
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())

    # Assert
    loaded = store.load(job.job_id)
    assert loaded.llm_plan is not None
    assert loaded.llm_plan.plan_id == plan.plan_id

    plan_path = jobs_dir / job.job_id / plan.rel_path
    assert plan_path.exists()
    plan_payload = json.loads(plan_path.read_text(encoding="utf-8"))
    assert plan_payload["plan_id"] == plan.plan_id

    plan_refs = [ref for ref in loaded.artifacts_index if ref.kind == ArtifactKind.PLAN_JSON]
    assert len(plan_refs) == 1
    assert plan_refs[0].rel_path == plan.rel_path


def test_freeze_plan_when_called_twice_is_idempotent(
    job_service,
    draft_service,
    plan_service,
    store,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))

    # Act
    first = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    second = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())

    # Assert
    assert second.plan_id == first.plan_id
    loaded = store.load(job.job_id)
    plan_refs = [ref for ref in loaded.artifacts_index if ref.kind == ArtifactKind.PLAN_JSON]
    assert len(plan_refs) == 1


def test_freeze_plan_when_confirmation_changes_raises_plan_already_frozen_error(
    job_service,
    draft_service,
    plan_service,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(notes="v1"))

    # Act / Assert
    with pytest.raises(PlanAlreadyFrozenError):
        plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(notes="v2"))
