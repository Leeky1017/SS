from __future__ import annotations

import shutil
import sys
import uuid
from pathlib import Path

from src.cli_support import create_job_services, create_template_run_service
from src.config import Config
from src.domain.do_template_run_service import DoTemplateRunService
from src.domain.job_service import JobService
from src.domain.stata_runner import RunResult
from src.infra.exceptions import SSError
from src.infra.stata_cmd import resolve_stata_cmd
from src.infra.stata_run_support import RunDirs, resolve_run_dirs
from src.utils.job_workspace import resolve_job_dir
from src.utils.tenancy import DEFAULT_TENANT_ID


def cmd_run_template(
    *, config: Config, template_id: str, param: list[str], timeout_seconds: int,
    input_csv: str | None, sample_data: bool,
) -> int:
    if bool(input_csv) and sample_data:
        return _print_error("--input-csv and --sample-data are mutually exclusive")
    params = _parse_params_or_error(values=param)
    if params is None:
        return 2
    stata_cmd = _resolve_stata_cmd_or_error(config=config)
    if stata_cmd is None:
        return 2
    store, state_machine, job_service = create_job_services(config=config)
    job_id, run_id, dirs = _create_job_and_dirs(
        job_service=job_service,
        jobs_dir=config.jobs_dir,
        template_id=template_id,
    )
    if dirs is None:
        return 2
    _prepare_run_inputs(work_dir=dirs.work_dir, input_csv=input_csv, sample_data=sample_data)
    svc = create_template_run_service(
        jobs_dir=config.jobs_dir,
        library_dir=config.do_template_library_dir,
        stata_cmd=stata_cmd,
        store=store,
        state_machine=state_machine,
    )
    result = _run_template_or_error(
        svc=svc,
        job_id=job_id,
        run_id=run_id,
        template_id=template_id,
        params=params,
        timeout_seconds=timeout_seconds,
    )
    if result is None:
        return 2

    _print_run_summary(
        jobs_dir=config.jobs_dir,
        tenant_id=DEFAULT_TENANT_ID,
        job_id=job_id,
        run_id=run_id,
        ok=result.ok,
        exit_code=result.exit_code,
    )
    return 0 if result.ok else 2


def _print_error(message: str) -> int:
    print(f"ERROR: {message}", file=sys.stderr)
    return 2


def _parse_params_or_error(*, values: list[str]) -> dict[str, str] | None:
    try:
        return _parse_params(values)
    except ValueError as e:
        _print_error(str(e))
        return None


def _resolve_stata_cmd_or_error(*, config: Config) -> list[str] | None:
    try:
        return resolve_stata_cmd(config)
    except SSError as e:
        _print_error(f"{e.error_code}: {e.message}")
        return None


def _create_job_and_dirs(
    *, job_service: JobService, jobs_dir: Path, template_id: str
) -> tuple[str, str, RunDirs | None]:
    job = job_service.create_job(
        tenant_id=DEFAULT_TENANT_ID,
        requirement=f"do_template:{template_id}",
        plan_revision=uuid.uuid4().hex,
    )
    run_id = uuid.uuid4().hex
    dirs = resolve_run_dirs(
        jobs_dir=jobs_dir,
        tenant_id=DEFAULT_TENANT_ID,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is None:
        _print_error("invalid job/run workspace")
        return job.job_id, run_id, None
    return job.job_id, run_id, dirs


def _run_template_or_error(
    *,
    svc: DoTemplateRunService,
    job_id: str,
    run_id: str,
    template_id: str,
    params: dict[str, str],
    timeout_seconds: int,
) -> RunResult | None:
    try:
        return svc.run(
            tenant_id=DEFAULT_TENANT_ID,
            job_id=job_id,
            template_id=template_id,
            params=params,
            timeout_seconds=timeout_seconds,
            run_id=run_id,
        )
    except SSError as e:
        _print_error(f"{e.error_code}: {e.message}")
        return None


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


def _print_run_summary(
    *,
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
