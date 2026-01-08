from __future__ import annotations

import asyncio
import json

import pytest

from src.domain.models import ArtifactKind, JobConfirmation, JobInputs
from src.infra.exceptions import PlanAlreadyFrozenError, PlanFreezeNotAllowedError
from src.utils.job_workspace import resolve_job_dir


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

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    plan_path = job_dir / plan.rel_path
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


def test_freeze_plan_for_single_file_job_builds_simple_sequential_plan(
    job_service,
    draft_service,
    plan_service,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))

    # Act
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())

    # Assert
    assert len(plan.steps) == 2
    generate = next(step for step in plan.steps if step.step_id == "generate_do")
    run = next(step for step in plan.steps if step.step_id == "run_stata")
    assert generate.params.get("composition_mode") == "sequential"
    assert run.params.get("composition_mode") == "sequential"
    assert generate.params.get("template_id") == "stub_descriptive_v1"
    bindings = generate.params.get("input_bindings")
    assert isinstance(bindings, dict)
    assert bindings.get("primary_dataset") == "input:primary"


def test_freeze_plan_with_multi_inputs_and_parallel_requirement_uses_parallel_then_aggregate(
    job_service,
    draft_service,
    plan_service,
    store,
    jobs_dir,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="analyze each dataset separately")
    asyncio.run(draft_service.preview(job_id=job.job_id))

    loaded = store.load(job.job_id)
    loaded.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    store.save(loaded)

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    inputs_dir = job_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    (inputs_dir / "manifest.json").write_text(
        json.dumps(
            {
                "schema_version": 1,
                "datasets": [{"dataset_key": "b"}, {"dataset_key": "a"}],
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )

    # Act
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())

    # Assert
    run = next(step for step in plan.steps if step.step_id == "run_stata")
    assert run.params.get("composition_mode") == "parallel_then_aggregate"
