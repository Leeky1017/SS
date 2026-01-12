from __future__ import annotations

import json
from pathlib import Path

from src.domain.do_file_generator import DoFileGenerator
from src.domain.models import ArtifactKind, JobStatus
from src.domain.output_formatter_service import OutputFormatterService
from src.domain.state_machine import JobStateMachine
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.stata_run_support import META_FILENAME
from src.utils.job_workspace import resolve_job_dir
from tests.fakes.fake_stata_runner import FakeStataRunner
from tests.worker_service_support import noop_sleep, prepare_queued_job, stata_do_library_dir


def test_worker_service_with_success_once_marks_job_succeeded(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)

    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[True]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    assert len(job.runs) == 1
    assert job.runs[0].status == "succeeded"
    assert any(ref.kind == ArtifactKind.RUN_META_JSON for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.DO_TEMPLATE_SOURCE for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.DO_TEMPLATE_META for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.DO_TEMPLATE_PARAMS for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.DO_TEMPLATE_RUN_META_JSON for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.STATA_RESULT_LOG for ref in job.artifacts_index)
    assert any(ref.kind == ArtifactKind.STATA_EXPORT_TABLE for ref in job.artifacts_index)
    run_id = job.runs[0].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    assert (job_dir / "runs" / run_id / "artifacts" / META_FILENAME).exists()
    assert (job_dir / "runs" / run_id / "artifacts" / "template" / "source.do").exists()
    assert (job_dir / "runs" / run_id / "artifacts" / "template" / "meta.json").exists()
    assert (job_dir / "runs" / run_id / "artifacts" / "template" / "params.json").exists()
    assert (job_dir / "runs" / run_id / "artifacts" / "do_template_run.meta.json").exists()
    outputs_dir = job_dir / "runs" / run_id / "artifacts" / "outputs"
    assert (outputs_dir / "result.log").exists()
    assert (outputs_dir / "table_TA14_quality_summary.csv").exists()
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_trigger_run_writes_queue_record_with_traceparent_matching_job_trace_id(
    tmp_path: Path,
) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)

    # Act
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)

    # Assert
    queued_files = list((queue_dir / "queued").glob("*.json"))
    assert len(queued_files) == 1
    record = json.loads(queued_files[0].read_text(encoding="utf-8"))
    traceparent = record.get("traceparent")
    assert isinstance(traceparent, str)
    parts = traceparent.split("-")
    assert len(parts) == 4
    trace_id = parts[1]
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.trace_id == trace_id


def test_worker_service_with_failure_then_success_retries_and_succeeds(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)

    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[False, True]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=3, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.SUCCEEDED
    assert len(job.runs) == 2
    assert job.runs[0].status == "failed"
    assert job.runs[1].status == "succeeded"
    assert job.runs[0].run_id != job.runs[1].run_id
    run_ids = {attempt.run_id for attempt in job.runs}
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    assert len(list((job_dir / "runs").iterdir())) == len(run_ids)
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_worker_service_with_failures_until_max_marks_job_failed(tmp_path: Path) -> None:
    # Arrange
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)

    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    service = WorkerService(
        store=JobStore(jobs_dir=jobs_dir),
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[False, False]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=2, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    # Act
    processed = service.process_next(worker_id="worker-1")

    # Assert
    assert processed is True
    job = JobStore(jobs_dir=jobs_dir).load(job_id)
    assert job.status == JobStatus.FAILED
    assert len(job.runs) == 2
    assert job.runs[0].status == "failed"
    assert job.runs[1].status == "failed"
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    for attempt in job.runs:
        assert (job_dir / "runs" / attempt.run_id / "artifacts" / META_FILENAME).exists()
    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []


def test_worker_service_with_output_formats_produces_converted_artifacts(tmp_path: Path) -> None:
    jobs_dir = tmp_path / "jobs"
    queue_dir = tmp_path / "queue"
    queue = FileWorkerQueue(queue_dir=queue_dir, lease_ttl_seconds=60)
    library_dir = stata_do_library_dir()
    job_id = prepare_queued_job(jobs_dir=jobs_dir, queue=queue, library_dir=library_dir)

    store = JobStore(jobs_dir=jobs_dir)
    job = store.load(job_id)
    job.output_formats = ["csv", "xlsx", "dta", "docx", "pdf", "log", "do"]
    store.save(job)

    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=FakeStataRunner(jobs_dir=jobs_dir, scripted_ok=[True]),
        output_formatter=OutputFormatterService(jobs_dir=jobs_dir),
        state_machine=JobStateMachine(),
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        do_file_generator=DoFileGenerator(do_template_repo=repo),
        sleep=noop_sleep,
    )

    processed = service.process_next(worker_id="worker-1")

    assert processed is True
    updated = store.load(job_id)
    assert updated.status == JobStatus.SUCCEEDED
    assert updated.runs

    run_id = updated.runs[-1].run_id
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    formatted_dir = job_dir / "runs" / run_id / "artifacts" / "formatted"
    assert (formatted_dir / "tables.xlsx").exists()
    assert (formatted_dir / "output.dta").exists()
    assert (formatted_dir / "report.docx").exists()
    assert (formatted_dir / "report.pdf").exists()

    rels = {ref.rel_path for ref in updated.artifacts_index}
    assert f"runs/{run_id}/artifacts/formatted/tables.xlsx" in rels
    assert f"runs/{run_id}/artifacts/formatted/output.dta" in rels
    assert f"runs/{run_id}/artifacts/formatted/report.docx" in rels
    assert f"runs/{run_id}/artifacts/formatted/report.pdf" in rels
    assert any(ref.kind == ArtifactKind.STATA_EXPORT_REPORT for ref in updated.artifacts_index)
