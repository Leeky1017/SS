from __future__ import annotations

import asyncio

import pytest

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import JobConfirmation, LLMPlan, PlanStep, PlanStepType
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError,
    DoFilePlanInvalidError,
    DoFileTemplateUnsupportedError,
)
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository


def test_generate_when_called_twice_with_same_inputs_is_deterministic(
    job_service,
    draft_service,
    plan_service,
    do_template_library_dir,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    generator = DoFileGenerator(
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir)
    )
    inputs_manifest = {"primary_dataset": {"rel_path": "inputs/data.dta"}}

    # Act
    first = generator.generate(plan=plan, inputs_manifest=inputs_manifest)
    second = generator.generate(plan=plan, inputs_manifest=inputs_manifest)

    # Assert
    assert second.do_file == first.do_file
    assert second.expected_outputs == first.expected_outputs
    assert 'copy "inputs/data.dta" "data.dta", replace' in first.do_file
    assert 'display "SS_TASK_BEGIN|id=TA14|level=L1|title=Data_Quality"' in first.do_file
    assert "local quality_threshold 0.8" in first.do_file
    assert len(first.expected_outputs) == 5
    filenames = {output.filename for output in first.expected_outputs}
    assert filenames == {
        "fig_TA14_quality_heatmap.png",
        "result.log",
        "table_TA14_issues.csv",
        "table_TA14_quality_summary.csv",
        "table_TA14_var_diagnostics.csv",
    }


def test_generate_with_missing_manifest_raises_inputs_manifest_invalid_error(
    job_service,
    draft_service,
    plan_service,
    do_template_library_dir,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    generator = DoFileGenerator(
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir)
    )

    # Act / Assert
    with pytest.raises(DoFileInputsManifestInvalidError) as exc:
        generator.generate(plan=plan, inputs_manifest={})
    assert exc.value.error_code == "DOFILE_INPUTS_MANIFEST_INVALID"


def test_generate_with_unknown_template_raises_template_unsupported_error():
    # Arrange
    plan = LLMPlan(
        plan_id="plan_1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="generate_do",
                type=PlanStepType.GENERATE_STATA_DO,
                params={"template": "unknown"},
                depends_on=[],
                produces=[],
            )
        ],
    )
    generator = DoFileGenerator()
    inputs_manifest = {"primary_dataset_rel_path": "inputs/data.dta"}

    # Act / Assert
    with pytest.raises(DoFileTemplateUnsupportedError) as exc:
        generator.generate(plan=plan, inputs_manifest=inputs_manifest)
    assert exc.value.error_code == "DOFILE_TEMPLATE_UNSUPPORTED"


def test_generate_with_missing_generate_step_raises_plan_invalid_error():
    # Arrange
    plan = LLMPlan(plan_id="plan_1", rel_path="artifacts/plan.json", steps=[])
    generator = DoFileGenerator()
    inputs_manifest = {"primary_dataset_rel_path": "inputs/data.dta"}

    # Act / Assert
    with pytest.raises(DoFilePlanInvalidError) as exc:
        generator.generate(plan=plan, inputs_manifest=inputs_manifest)
    assert exc.value.error_code == "DOFILE_PLAN_INVALID"


def test_generate_with_csv_manifest_uses_import_delimited(
    job_service,
    draft_service,
    plan_service,
    do_template_library_dir,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    generator = DoFileGenerator(
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir)
    )
    inputs_manifest = {
        "schema_version": 2,
        "datasets": [
            {
                "dataset_key": "ds_demo",
                "role": "primary_dataset",
                "rel_path": "inputs/data.csv",
                "original_name": "data.csv",
                "size_bytes": 1,
                "sha256": "x",
                "fingerprint": "sha256:x",
                "format": "csv",
                "uploaded_at": "2026-01-01T00:00:00Z",
                "content_type": "text/csv",
            }
        ],
    }

    # Act
    rendered = generator.generate(plan=plan, inputs_manifest=inputs_manifest).do_file

    # Assert
    assert 'copy "inputs/data.csv" "data.csv", replace' in rendered
