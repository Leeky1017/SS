from __future__ import annotations

import asyncio

import pytest

from src.domain.do_file_generator import DEFAULT_SUMMARY_TABLE_FILENAME, DoFileGenerator
from src.domain.models import ArtifactKind, JobConfirmation, LLMPlan, PlanStep, PlanStepType
from src.infra.exceptions import (
    DoFileInputsManifestInvalidError,
    DoFilePlanInvalidError,
    DoFileTemplateUnsupportedError,
)


def test_generate_when_called_twice_with_same_inputs_is_deterministic(
    job_service,
    draft_service,
    plan_service,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    generator = DoFileGenerator()
    inputs_manifest = {"primary_dataset": {"rel_path": "inputs/data.dta"}}

    # Act
    first = generator.generate(plan=plan, inputs_manifest=inputs_manifest)
    second = generator.generate(plan=plan, inputs_manifest=inputs_manifest)

    # Assert
    assert second.do_file == first.do_file
    assert second.expected_outputs == first.expected_outputs
    assert 'use "../../inputs/data.dta", clear' in first.do_file
    assert "describe" in first.do_file
    assert "summarize" in first.do_file
    assert f'export delimited using "{DEFAULT_SUMMARY_TABLE_FILENAME}", replace' in first.do_file
    assert len(first.expected_outputs) == 1
    assert first.expected_outputs[0].kind == ArtifactKind.STATA_EXPORT_TABLE
    assert first.expected_outputs[0].filename == DEFAULT_SUMMARY_TABLE_FILENAME


def test_generate_with_missing_manifest_raises_inputs_manifest_invalid_error(
    job_service,
    draft_service,
    plan_service,
):
    # Arrange
    job = job_service.create_job(requirement="need a descriptive analysis")
    asyncio.run(draft_service.preview(job_id=job.job_id))
    plan = plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation())
    generator = DoFileGenerator()

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
