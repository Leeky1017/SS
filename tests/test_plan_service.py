from __future__ import annotations

import asyncio
import json

import pytest

from src.domain.models import ArtifactKind, JobConfirmation, JobInputs
from src.domain.plan_service import PlanService
from src.infra.exceptions import (
    DoTemplateIndexCorruptedError,
    DoTemplateMetaNotFoundError,
    PlanAlreadyFrozenError,
    PlanFreezeNotAllowedError,
    PlanTemplateMetaInvalidError,
    PlanTemplateMetaNotFoundError,
)
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.plan_exceptions import PlanFreezeMissingRequiredError
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
    generate_step = next(step for step in plan_payload["steps"] if step["step_id"] == "generate_do")
    contract = generate_step["params"]["template_contract"]
    assert contract["template_id"] == generate_step["params"]["template_id"]
    assert isinstance(contract["dependencies"], list)
    assert "params_contract" in contract
    assert contract["outputs_contract"]["archive_dir_rel_path"] == "runs/{run_id}/artifacts/outputs"

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
    assert generate.params.get("template_id") == "TA14"
    params = generate.params.get("template_params")
    assert isinstance(params, dict)
    assert params.get("__QUALITY_THRESHOLD__") == "0.8"
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


def test_freeze_plan_when_template_meta_missing_raises_plan_template_meta_not_found_error(
    job_service,
    draft_service,
    store,
    jobs_dir,
    do_template_library_dir,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    loaded = store.load(job.job_id)
    loaded.selected_template_id = "T01"
    store.save(loaded)

    class Repo:
        def list_template_ids(self) -> tuple[str, ...]:
            return ("T01",)

        def get_template(self, *, template_id: str):  # noqa: ANN201
            raise DoTemplateMetaNotFoundError(
                template_id=template_id,
                path="/tmp/missing.meta.json",
            )

    service = PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
        do_template_repo=Repo(),
    )

    # Act / Assert
    with pytest.raises(PlanTemplateMetaNotFoundError) as excinfo:
        service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    assert excinfo.value.error_code == "PLAN_TEMPLATE_META_NOT_FOUND"
    assert job.job_id in excinfo.value.message
    assert "template_id=T01" in excinfo.value.message


def test_freeze_plan_when_template_meta_corrupt_raises_plan_template_meta_invalid_error(
    job_service,
    draft_service,
    store,
    jobs_dir,
    do_template_library_dir,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    loaded = store.load(job.job_id)
    loaded.selected_template_id = "T01"
    store.save(loaded)

    class Repo:
        def list_template_ids(self) -> tuple[str, ...]:
            return ("T01",)

        def get_template(self, *, template_id: str):  # noqa: ANN201
            raise DoTemplateIndexCorruptedError(reason="meta.json_invalid", template_id=template_id)

    service = PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=do_template_library_dir),
        do_template_repo=Repo(),
    )

    # Act / Assert
    with pytest.raises(PlanTemplateMetaInvalidError) as excinfo:
        service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    assert excinfo.value.error_code == "PLAN_TEMPLATE_META_INVALID"
    assert job.job_id in excinfo.value.message
    assert "template_id=T01" in excinfo.value.message


def test_freeze_plan_when_required_template_param_missing_raises_plan_freeze_missing_required_error(
    job_service,
    draft_service,
    plan_service,
    store,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    loaded = store.load(job.job_id)
    loaded.selected_template_id = "T01"
    store.save(loaded)

    # Act / Assert
    with pytest.raises(PlanFreezeMissingRequiredError) as excinfo:
        plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    assert excinfo.value.error_code == "PLAN_FREEZE_MISSING_REQUIRED"
    assert "__NUMERIC_VARS__" in excinfo.value.details.get("missing_params", [])


def test_freeze_plan_when_missing_template_param_fixed_allows_freeze(
    job_service,
    draft_service,
    plan_service,
    store,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    loaded = store.load(job.job_id)
    loaded.selected_template_id = "T01"
    assert loaded.draft is not None
    loaded.draft = loaded.draft.model_copy(update={"outcome_var": "x"})
    store.save(loaded)

    # Act
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())

    # Assert
    generate = next(step for step in plan.steps if step.step_id == "generate_do")
    assert generate.params.get("template_id") == "T01"
