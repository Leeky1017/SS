from __future__ import annotations

import json
from pathlib import Path

from src.config import Config
from src.domain.do_template_run_service import DoTemplateRunService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.job_store import JobStore
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store_factory import build_job_store
from src.infra.local_stata_runner import LocalStataRunner
from src.utils.json_types import JsonObject


def create_job_services(*, config: Config) -> tuple[JobStore, JobStateMachine, JobService]:
    store = build_job_store(config=config)
    state_machine = JobStateMachine()
    plan_service = PlanService(store=store)
    job_service = JobService(
        store=store,
        scheduler=NoopJobScheduler(),
        plan_service=plan_service,
        state_machine=state_machine,
        idempotency=JobIdempotency(),
    )
    return store, state_machine, job_service


def create_template_run_service(
    *,
    jobs_dir: Path,
    library_dir: Path,
    stata_cmd: list[str],
    store: JobStore,
    state_machine: JobStateMachine,
) -> DoTemplateRunService:
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    runner = LocalStataRunner(jobs_dir=jobs_dir, stata_cmd=stata_cmd)
    return DoTemplateRunService(
        store=store,
        runner=runner,
        repo=repo,
        state_machine=state_machine,
        jobs_dir=jobs_dir,
    )


def write_json_report(*, path: Path, payload: JsonObject) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
    path.write_text(data + "\n", encoding="utf-8")

