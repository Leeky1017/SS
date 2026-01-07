from __future__ import annotations

from pathlib import Path

from src.cli_support import create_job_services, create_template_run_service, write_json_report
from src.config import Config
from src.domain.stata_smoke_suite import (
    DEFAULT_SMOKE_MANIFEST_REL_PATH,
    SmokeSuiteManifest,
    load_smoke_suite_manifest,
    run_smoke_suite,
)
from src.infra.exceptions import SSError
from src.infra.stata_cmd import resolve_stata_cmd
from src.utils.json_types import JsonObject


def cmd_run_smoke_suite(
    *, config: Config, manifest_arg: str | None, report_path: str, timeout_seconds: int
) -> int:
    library_dir = config.do_template_library_dir
    manifest_path = _resolve_manifest_path(library_dir=library_dir, manifest_arg=manifest_arg)
    manifest = load_smoke_suite_manifest(path=manifest_path)
    report = _build_report(config=config, manifest=manifest, timeout_seconds=timeout_seconds)
    write_json_report(path=Path(report_path).expanduser(), payload=report)
    print(f"report_path={report_path}")
    return 0 if _is_all_passed(report=report, total=len(manifest.templates)) else 2


def _is_all_passed(*, report: JsonObject, total: int) -> bool:
    summary = report.get("summary", {})
    if not isinstance(summary, dict):
        return False
    return summary.get("passed") == total


def _resolve_manifest_path(*, library_dir: Path, manifest_arg: str | None) -> Path:
    if manifest_arg is not None:
        return Path(manifest_arg).expanduser()
    return library_dir / DEFAULT_SMOKE_MANIFEST_REL_PATH


def _build_report(
    *, config: Config, manifest: SmokeSuiteManifest, timeout_seconds: int
) -> JsonObject:
    library_dir = config.do_template_library_dir
    try:
        stata_cmd = resolve_stata_cmd(config)
    except SSError as e:
        report = run_smoke_suite(
            manifest=manifest,
            library_dir=library_dir,
            job_service=None,
            template_runner=None,
            stata_cmd=None,
            timeout_seconds=timeout_seconds,
        )
        report["stata_cmd_error"] = {"error_code": e.error_code, "message": e.message}
        return report

    store, state_machine, job_service = create_job_services(config=config)
    template_runner = create_template_run_service(
        jobs_dir=config.jobs_dir,
        library_dir=library_dir,
        stata_cmd=stata_cmd,
        store=store,
        state_machine=state_machine,
    )
    return run_smoke_suite(
        manifest=manifest,
        library_dir=library_dir,
        job_service=job_service,
        template_runner=template_runner,
        stata_cmd=stata_cmd,
        timeout_seconds=timeout_seconds,
    )
