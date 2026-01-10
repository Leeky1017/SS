from __future__ import annotations

from datetime import datetime
from pathlib import Path

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import JobInputs, LLMPlan, PlanStep, PlanStepType
from src.domain.worker_plan_executor import execute_plan
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.utils.job_workspace import resolve_job_dir


class _FailIfCalledRunner:
    def run(
        self,
        *,
        tenant_id: str = "default",
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ):
        raise AssertionError("runner must not be invoked when required template params are missing")


def test_execute_plan_when_required_template_param_missing_returns_error_and_skips_runner(
    job_service,
    store,
    jobs_dir: Path,
    do_template_library_dir: Path,
) -> None:
    # Arrange
    job = job_service.create_job(requirement="test")
    job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    job.llm_plan = LLMPlan(
        plan_id="plan_1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="generate_do",
                type=PlanStepType.GENERATE_STATA_DO,
                params={"template_id": "T01", "template_params": {}},
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="run_stata",
                type=PlanStepType.RUN_STATA,
                params={"timeout_seconds": 10},
                depends_on=["generate_do"],
                produces=[],
            ),
        ],
    )
    store.save(job)

    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job.job_id)
    assert job_dir is not None
    (job_dir / "inputs").mkdir(parents=True, exist_ok=True)
    (job_dir / "inputs" / "manifest.json").write_text(
        '{\n  "primary_dataset": {"rel_path": "inputs/data.dta"}\n}\n',
        encoding="utf-8",
    )

    generator = DoFileGenerator(
        do_template_repo=FileSystemDoTemplateRepository(library_dir=do_template_library_dir)
    )

    # Act
    result = execute_plan(
        job=job,
        run_id="run-1",
        jobs_dir=jobs_dir,
        runner=_FailIfCalledRunner(),
        shutdown_deadline=None,
        clock=lambda: datetime(2026, 1, 1),
        do_file_generator=generator,
    )

    # Assert
    assert result.ok is False
    assert result.error is not None
    assert result.error.error_code == "DO_TEMPLATE_PARAM_MISSING"

    do_artifact_path = job_dir / "runs" / "run-1" / "artifacts" / "stata.do"
    assert do_artifact_path.exists() is False
