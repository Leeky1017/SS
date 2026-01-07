from __future__ import annotations

import argparse
import shutil
import sys
import uuid
from pathlib import Path

from src.config import Config, load_config
from src.domain.do_template_run_service import DoTemplateRunService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobService, NoopJobScheduler
from src.domain.job_store import JobStore
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import SSError
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store_factory import build_job_store
from src.infra.local_stata_runner import LocalStataRunner
from src.infra.logging_config import configure_logging
from src.infra.stata_cmd import resolve_stata_cmd
from src.infra.stata_run_support import resolve_run_dirs
from src.utils.job_workspace import resolve_job_dir
from src.utils.tenancy import DEFAULT_TENANT_ID


def _parse_params(values: list[str]) -> dict[str, str]:
    params: dict[str, str] = {}
    for item in values:
        if "=" not in item:
            raise ValueError(f"invalid --param (expected NAME=VALUE): {item}")
        name, value = item.split("=", 1)
        if name.strip() == "":
            raise ValueError(f"invalid --param (empty name): {item}")
        params[name] = value
    return params


def _write_sample_data_csv(path: Path) -> None:
    rows = [
        "id,time,y,x1",
        "1,1,10,2",
        "1,2,11,3",
        "1,3,12,4",
        "2,1,9,2",
        "2,2,10,2",
        "2,3,11,3",
    ]
    path.write_text("\n".join(rows) + "\n", encoding="utf-8")


def _prepare_run_inputs(*, work_dir: Path, input_csv: str | None, sample_data: bool) -> None:
    if input_csv is None and not sample_data:
        return
    work_dir.mkdir(parents=True, exist_ok=True)
    target = work_dir / "data.csv"
    if sample_data:
        _write_sample_data_csv(target)
        return
    if input_csv is None:
        return
    shutil.copy2(Path(input_csv), target)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="ss")
    sub = parser.add_subparsers(dest="cmd", required=True)

    list_cmd = sub.add_parser("list-templates", help="List template ids")
    list_cmd.add_argument("--limit", type=int, default=50)

    run_cmd = sub.add_parser(
        "run-template",
        help="Run a template end-to-end (generate do-file, run Stata, archive artifacts)",
    )
    run_cmd.add_argument("--template-id", required=True)
    run_cmd.add_argument("--param", action="append", default=[])
    run_cmd.add_argument("--timeout-seconds", type=int, default=300)
    run_cmd.add_argument("--input-csv")
    run_cmd.add_argument("--sample-data", action="store_true")
    return parser


def _cmd_list_templates(*, library_dir: Path, limit: int) -> int:
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    ids = repo.list_template_ids()
    for template_id in ids[: max(0, int(limit))]:
        print(template_id)
    return 0


def _print_run_summary(
    jobs_dir: Path,
    tenant_id: str,
    job_id: str,
    run_id: str,
    ok: bool,
    exit_code: int | None,
) -> None:
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, tenant_id=tenant_id, job_id=job_id)
    artifacts_dir = None if job_dir is None else job_dir / "runs" / run_id / "artifacts"
    print(f"job_id={job_id}")
    print(f"run_id={run_id}")
    print(f"ok={ok}")
    print(f"exit_code={exit_code}")
    print(f"artifacts_dir={artifacts_dir}")


def _create_job_services(*, config: Config) -> tuple[JobStore, JobStateMachine, JobService]:
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


def _create_template_run_service(
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


def _cmd_run_template(
    *,
    config: Config,
    library_dir: Path,
    stata_cmd: list[str],
    template_id: str,
    param: list[str],
    timeout_seconds: int,
    input_csv: str | None,
    sample_data: bool,
) -> int:
    try:
        params = _parse_params(param)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 2

    store, state_machine, job_service = _create_job_services(config=config)
    job = job_service.create_job(
        tenant_id=DEFAULT_TENANT_ID,
        requirement=f"do_template:{template_id}",
        plan_revision=uuid.uuid4().hex,
    )
    run_id = uuid.uuid4().hex
    dirs = resolve_run_dirs(
        jobs_dir=config.jobs_dir,
        tenant_id=DEFAULT_TENANT_ID,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is None:
        print("ERROR: invalid job/run workspace", file=sys.stderr)
        return 2
    _prepare_run_inputs(work_dir=dirs.work_dir, input_csv=input_csv, sample_data=sample_data)
    svc = _create_template_run_service(
        jobs_dir=config.jobs_dir,
        library_dir=library_dir,
        stata_cmd=stata_cmd,
        store=store,
        state_machine=state_machine,
    )

    try:
        result = svc.run(
            tenant_id=DEFAULT_TENANT_ID,
            job_id=job.job_id,
            template_id=template_id,
            params=params,
            timeout_seconds=timeout_seconds,
            run_id=run_id,
        )
    except SSError as e:
        print(f"ERROR: {e.error_code}: {e.message}", file=sys.stderr)
        return 2

    _print_run_summary(
        config.jobs_dir,
        DEFAULT_TENANT_ID,
        job.job_id,
        run_id,
        result.ok,
        result.exit_code,
    )
    return 0 if result.ok else 2


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    config = load_config()
    configure_logging(log_level=config.log_level)

    if args.cmd == "list-templates":
        return _cmd_list_templates(
            library_dir=config.do_template_library_dir,
            limit=int(args.limit),
        )

    if args.cmd != "run-template":
        return 2

    if bool(args.input_csv) and bool(args.sample_data):
        print("ERROR: --input-csv and --sample-data are mutually exclusive", file=sys.stderr)
        return 2

    try:
        stata_cmd = resolve_stata_cmd(config)
    except SSError as e:
        print(f"ERROR: {e.error_code}: {e.message}", file=sys.stderr)
        return 2

    return _cmd_run_template(
        config=config,
        library_dir=config.do_template_library_dir,
        stata_cmd=stata_cmd,
        template_id=str(args.template_id),
        param=list(args.param),
        timeout_seconds=int(args.timeout_seconds),
        input_csv=str(args.input_csv) if args.input_csv is not None else None,
        sample_data=bool(args.sample_data),
    )


if __name__ == "__main__":
    raise SystemExit(main())
