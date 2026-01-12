from __future__ import annotations

import json
from pathlib import Path

from src.domain.do_file_generator import DoFileGenerator
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.models import (
    ArtifactKind,
    JobInputs,
    JobStatus,
    LLMPlan,
    PlanStep,
    PlanStepType,
)
from src.domain.output_formatter_service import OutputFormatterService
from src.domain.plan_service import PlanService
from src.domain.stata_dependency_checker import StataDependencyCheckResult
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.infra.stata_run_support import ERROR_FILENAME
from src.utils.job_workspace import resolve_job_dir
from tests.fakes.fake_stata_runner import FakeStataRunner
from tests.worker_service_support import (
    noop_sleep,
    prepare_queued_job,
    stata_do_library_dir,
    write_job_inputs,
)


def test_worker_service_when_plan_missing_persists_error_artifacts_and_marks_job_failed(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)
    store = JobStore(jobs_dir=jobs_dir)
    job = store.load(job_id)
    job.llm_plan = None
    store.save(job)

    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=noop_sleep,
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
    payload = json.loads(
        (job_dir / "runs" / run_id / "artifacts" / ERROR_FILENAME).read_text(encoding="utf-8")
    )
    assert payload["error_code"] == "PLAN_MISSING"


def test_worker_service_when_inputs_manifest_missing_persists_error_artifacts_and_marks_job_failed(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)
    store = JobStore(jobs_dir=jobs_dir)
    job = store.load(job_id)
    job.inputs = None
    store.save(job)

    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=noop_sleep,
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
    payload = json.loads(
        (job_dir / "runs" / run_id / "artifacts" / ERROR_FILENAME).read_text(encoding="utf-8")
    )
    assert payload["error_code"] == "INPUTS_MANIFEST_MISSING"


class _FakeDependencyChecker:
    def __init__(self, *, missing_pkgs: set[str]) -> None:
        self._missing_pkgs = set(missing_pkgs)

    def check(self, *, tenant_id: str = "default", job_id: str, run_id: str, dependencies):
        missing = tuple(dep for dep in dependencies if dep.pkg in self._missing_pkgs)
        return StataDependencyCheckResult(missing=missing, error=None)


def test_worker_service_when_dependency_missing_writes_structured_error_and_retry_succeeds(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    store = JobStore(jobs_dir=jobs_dir)
    scheduler = QueueJobScheduler(queue=queue)
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    plan_service = PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=library_dir),
        do_template_repo=repo,
    )
    job_service = JobService(
        store=store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=JobStateMachine(),
        idempotency=JobIdempotency(),
    )

    job = job_service.create_job(requirement="hello")
    job.status = JobStatus.QUEUED
    job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    job.llm_plan = LLMPlan(
        plan_id="plan-1",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="generate_do",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "template_id": "TO06",
                    "template_params": {"__DEPVAR__": "y", "__INDEPVARS__": "x"},
                    "template_contract": {
                        "dependencies": [
                            {"pkg": "outreg2", "purpose": "Table export", "source": "ssc"}
                        ]
                    },
                },
                depends_on=[],
                produces=[ArtifactKind.STATA_DO],
            ),
            PlanStep(
                step_id="run_stata",
                type=PlanStepType.RUN_STATA,
                params={"timeout_seconds": 300},
                depends_on=["generate_do"],
                produces=[],
            ),
        ],
    )
    store.save(job)
    write_job_inputs(jobs_dir=jobs_dir, job_id=job.job_id)
    scheduler.schedule(job=job)
    job_id = job.job_id

    fail_service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[True]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        dependency_checker=_FakeDependencyChecker(missing_pkgs={"outreg2"}),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    # Act (1): missing dependency → failed (non-retriable)
    processed = fail_service.process_next(worker_id="worker-1")

    # Assert (1)
    assert processed is True
    failed = store.load(job_id)
    assert failed.status == JobStatus.FAILED
    assert len(failed.runs) == 1
    run_id = failed.runs[0].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    payload = json.loads(
        (job_dir / "runs" / run_id / "artifacts" / ERROR_FILENAME).read_text(encoding="utf-8")
    )
    assert payload["error_code"] == "STATA_DEPENDENCY_MISSING"
    missing = payload["details"]["missing_dependencies"]
    assert {"pkg": "outreg2", "source": "ssc", "purpose": "Table export"} in missing

    # Arrange (2): fix env (dependency available) → retry same job
    job_service.trigger_run(job_id=job_id)

    succeed_service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[True]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        dependency_checker=_FakeDependencyChecker(missing_pkgs=set()),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    # Act (2): retry succeeds
    processed = succeed_service.process_next(worker_id="worker-1")

    # Assert (2)
    assert processed is True
    succeeded = store.load(job_id)
    assert succeeded.status == JobStatus.SUCCEEDED
    assert len(succeeded.runs) == 2
