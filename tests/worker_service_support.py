from __future__ import annotations

import json
from pathlib import Path

from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService
from src.domain.models import JobConfirmation, JobInputs, JobStatus
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store import JobStore
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.utils.job_workspace import resolve_job_dir


def stata_do_library_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "assets" / "stata_do_library"


def write_job_inputs(*, jobs_dir: Path, job_id: str) -> None:
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
    assert job_dir is not None
    inputs_dir = job_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)
    dataset_rel_path = "inputs/primary.csv"
    (inputs_dir / "primary.csv").write_text("id,y,x\n1,1,2\n", encoding="utf-8")
    (inputs_dir / "manifest.json").write_text(
        json.dumps({"primary_dataset": {"rel_path": dataset_rel_path}}, indent=2, sort_keys=True)
        + "\n",
        encoding="utf-8",
    )


def prepare_queued_job(
    *,
    jobs_dir: Path,
    queue: FileWorkerQueue,
    library_dir: Path | None = None,
) -> str:
    effective_library_dir = stata_do_library_dir() if library_dir is None else library_dir
    store = JobStore(jobs_dir=jobs_dir)
    scheduler = QueueJobScheduler(queue=queue)
    plan_service = PlanService(
        store=store,
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=effective_library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=effective_library_dir),
    )
    job_service = JobService(
        store=store,
        scheduler=scheduler,
        plan_service=plan_service,
        state_machine=JobStateMachine(),
        idempotency=JobIdempotency(),
    )
    job = job_service.create_job(requirement="hello")
    job.status = JobStatus.DRAFT_READY
    job.inputs = JobInputs(manifest_rel_path="inputs/manifest.json", fingerprint="fp-test")
    store.save(job)
    write_job_inputs(jobs_dir=jobs_dir, job_id=job.job_id)
    plan_service.freeze_plan(job_id=job.job_id, confirmation=JobConfirmation(requirement="hello"))
    job_service.trigger_run(job_id=job.job_id)
    return job.job_id


def noop_sleep(_seconds: float) -> None:
    return None
