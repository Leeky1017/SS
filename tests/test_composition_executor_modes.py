from __future__ import annotations

import json
import uuid
from pathlib import Path

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import (
    JOB_SCHEMA_VERSION_CURRENT,
    ArtifactKind,
    Job,
    JobInputs,
    JobStatus,
    LLMPlan,
    PlanStep,
    PlanStepType,
)
from src.domain.output_formatter_service import OutputFormatterService
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.utils.job_workspace import resolve_job_dir
from src.utils.time import utc_now
from tests.fakes.fake_stata_runner import FakeStataRunner


def _write_inputs_manifest(*, job_dir: Path, datasets: list[dict[str, str]]) -> None:
    inputs_dir = job_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    payload = {"schema_version": 2, "datasets": datasets}
    (inputs_dir / "manifest.json").write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _write_csv(*, job_dir: Path, rel_path: str, content: str) -> None:
    path = job_dir / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _queued_job_with_plan(
    *, jobs_dir: Path, queue: FileWorkerQueue, plan: LLMPlan, datasets: list[dict[str, str]]
) -> str:
    store = JobStore(jobs_dir=jobs_dir)
    job_id = f"job_{uuid.uuid4().hex}"
    job = Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        job_id=job_id,
        status=JobStatus.QUEUED,
        created_at=utc_now().isoformat(),
        scheduled_at=utc_now().isoformat(),
        requirement="test",
        inputs=JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test"),
        llm_plan=plan,
        runs=[],
        artifacts_index=[],
    )
    store.create(job)
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    _write_inputs_manifest(job_dir=job_dir, datasets=datasets)
    queue.enqueue(job_id)
    return job_id


def _worker(*, jobs_dir: Path, queue: FileWorkerQueue) -> WorkerService:
    library_dir = Path(__file__).resolve().parents[1] / "assets" / "stata_do_library"
    return WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=2, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(
            do_template_repo=FileSystemDoTemplateRepository(library_dir=library_dir)
        ),
        sleep=lambda _s: None,
    )


def test_composition_executor_merge_then_sequential_writes_merged_product_and_summary(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    plan = LLMPlan(
        plan_id="plan-merge",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="merge",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "merge_then_sequential",
                    "template_id": "TA14",
                    "input_bindings": {
                        "primary_dataset": "input:main",
                        "secondary_dataset": "input:controls",
                    },
                    "merge": {"operation": "merge", "keys": ["id"]},
                    "products": [{"product_id": "merged", "kind": "dataset"}],
                },
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="analysis",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "merge_then_sequential",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "prod:merge:merged"},
                    "products": [],
                },
                depends_on=["merge"],
                produces=[],
            ),
        ],
    )
    datasets = [
        {"dataset_key": "main", "role": "primary_dataset", "rel_path": "inputs/main.csv"},
        {"dataset_key": "controls", "role": "secondary_dataset", "rel_path": "inputs/controls.csv"},
    ]
    job_id = _queued_job_with_plan(jobs_dir=jobs_dir, queue=queue, plan=plan, datasets=datasets)
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    _write_csv(job_dir=job_dir, rel_path="inputs/main.csv", content="id,x\n1,10\n2,20\n")
    _write_csv(job_dir=job_dir, rel_path="inputs/controls.csv", content="id,y\n1,100\n2,200\n")

    service = _worker(jobs_dir=jobs_dir, queue=queue)

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    pipeline_run_id = job.runs[0].run_id
    summary_path = job_dir / "runs" / pipeline_run_id / "artifacts" / "composition_summary.json"
    assert summary_path.exists()
    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    assert payload["composition_mode"] == "merge_then_sequential"
    assert any(d.get("type") == "merge" for d in payload.get("decisions", []))
    assert any(ref.kind == ArtifactKind.COMPOSITION_SUMMARY_JSON for ref in job.artifacts_index)

    merged_path = (
        job_dir
        / "runs"
        / f"{pipeline_run_id}__merge"
        / "artifacts"
        / "products"
        / "merged.csv"
    )
    assert merged_path.exists()
    merged = merged_path.read_text(encoding="utf-8")
    assert "y" in merged


def test_composition_executor_parallel_then_aggregate_writes_products_and_summary(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    plan = LLMPlan(
        plan_id="plan-parallel",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="analyze_a",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "parallel_then_aggregate",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:a"},
                    "products": [{"product_id": "summary", "kind": "table"}],
                },
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="analyze_b",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "parallel_then_aggregate",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:b"},
                    "products": [{"product_id": "summary", "kind": "table"}],
                },
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="aggregate",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "parallel_then_aggregate",
                    "template_id": "TA14",
                    "input_bindings": {
                        "primary_dataset": "prod:analyze_a:summary",
                        "secondary_dataset": "prod:analyze_b:summary",
                    },
                    "products": [],
                },
                depends_on=["analyze_a", "analyze_b"],
                produces=[],
            ),
        ],
    )
    datasets = [
        {"dataset_key": "a", "role": "primary_dataset", "rel_path": "inputs/a.csv"},
        {"dataset_key": "b", "role": "secondary_dataset", "rel_path": "inputs/b.csv"},
    ]
    job_id = _queued_job_with_plan(jobs_dir=jobs_dir, queue=queue, plan=plan, datasets=datasets)
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    _write_csv(job_dir=job_dir, rel_path="inputs/a.csv", content="id,x\n1,10\n")
    _write_csv(job_dir=job_dir, rel_path="inputs/b.csv", content="id,x\n2,20\n")

    service = _worker(jobs_dir=jobs_dir, queue=queue)

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    pipeline_run_id = job.runs[0].run_id
    summary_path = job_dir / "runs" / pipeline_run_id / "artifacts" / "composition_summary.json"
    assert summary_path.exists()
    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    assert payload["composition_mode"] == "parallel_then_aggregate"

    prod_a = (
        job_dir
        / "runs"
        / f"{pipeline_run_id}__analyze_a"
        / "artifacts"
        / "products"
        / "summary.csv"
    )
    prod_b = (
        job_dir
        / "runs"
        / f"{pipeline_run_id}__analyze_b"
        / "artifacts"
        / "products"
        / "summary.csv"
    )
    assert prod_a.exists()
    assert prod_b.exists()


def test_composition_executor_conditional_executes_one_branch_and_records_decision(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    plan = LLMPlan(
        plan_id="plan-conditional",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="condition",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "conditional",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:main"},
                    "condition": {
                        "predicate": {"op": "always_true"},
                        "true_steps": ["branch_true"],
                        "false_steps": ["branch_false"],
                    },
                    "products": [],
                },
                depends_on=[],
                produces=[],
            ),
            PlanStep(
                step_id="branch_true",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "conditional",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:main"},
                    "products": [],
                },
                depends_on=["condition"],
                produces=[],
            ),
            PlanStep(
                step_id="branch_false",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "conditional",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:main"},
                    "products": [],
                },
                depends_on=["condition"],
                produces=[],
            ),
        ],
    )
    datasets = [{"dataset_key": "main", "role": "primary_dataset", "rel_path": "inputs/main.csv"}]
    job_id = _queued_job_with_plan(jobs_dir=jobs_dir, queue=queue, plan=plan, datasets=datasets)
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    _write_csv(job_dir=job_dir, rel_path="inputs/main.csv", content="id,x\n1,10\n")

    service = _worker(jobs_dir=jobs_dir, queue=queue)

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    pipeline_run_id = job.runs[0].run_id
    summary_path = job_dir / "runs" / pipeline_run_id / "artifacts" / "composition_summary.json"
    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    decisions = payload.get("decisions", [])
    assert any(
        d.get("type") == "conditional" and d.get("selected_branch") == "true"
        for d in decisions
    )
    steps = payload.get("steps", [])
    assert any(s.get("step_id") == "branch_false" and s.get("status") == "skipped" for s in steps)
    assert not (job_dir / "runs" / f"{pipeline_run_id}__branch_false").exists()


def test_composition_executor_with_unknown_dataset_ref_fails_and_writes_error_artifacts(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    plan = LLMPlan(
        plan_id="plan-invalid-ref",
        rel_path="artifacts/plan.json",
        steps=[
            PlanStep(
                step_id="analysis",
                type=PlanStepType.GENERATE_STATA_DO,
                params={
                    "composition_mode": "sequential",
                    "template_id": "TA14",
                    "input_bindings": {"primary_dataset": "input:unknown"},
                    "products": [],
                },
                depends_on=[],
                produces=[],
            )
        ],
    )
    datasets = [{"dataset_key": "main", "role": "primary_dataset", "rel_path": "inputs/main.csv"}]
    job_id = _queued_job_with_plan(jobs_dir=jobs_dir, queue=queue, plan=plan, datasets=datasets)
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    _write_csv(job_dir=job_dir, rel_path="inputs/main.csv", content="id,x\n1,10\n")

    service = _worker(jobs_dir=jobs_dir, queue=queue)

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.FAILED
    assert len(job.runs) == 1
    pipeline_run_id = job.runs[0].run_id
    error_path = job_dir / "runs" / pipeline_run_id / "artifacts" / "run.error.json"
    assert error_path.exists()
    payload = json.loads(error_path.read_text(encoding="utf-8"))
    assert payload["error_code"] == "PLAN_COMPOSITION_INVALID"
