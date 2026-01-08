from __future__ import annotations

import json
import re
import shutil
import uuid
from pathlib import Path
from typing import Sequence, cast

from src.domain.do_template_run_service import DoTemplateRunService
from src.domain.job_service import JobService
from src.domain.stata_runner import RunResult
from src.domain.stata_smoke_suite_manifest import SmokeSuiteManifest, SmokeSuiteTemplate
from src.infra.exceptions import SSError
from src.infra.stata_run_support import resolve_run_dirs
from src.utils.json_types import JsonObject, JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

_DEP_CHECK_MISSING = re.compile(
    r"^SS_DEP_CHECK\\|pkg=(?P<pkg>[^|]+)\\|.*\\|status=missing\\s*$"
)
_DEP_MISSING = re.compile(r"^SS_DEP_MISSING(?::|\\|pkg=)(?P<pkg>[A-Za-z0-9_]+)\\s*$")


def _error_case(
    template_id: str,
    error_code: str,
    message: str,
    *,
    job_id: str | None = None,
    run_id: str | None = None,
    artifacts_dir: Path | None = None,
) -> JsonObject:
    payload: JsonObject = {
        "template_id": template_id,
        "status": "error",
        "error": {"error_code": error_code, "message": message},
    }
    if job_id is not None:
        payload["job_id"] = job_id
    if run_id is not None:
        payload["run_id"] = run_id
    if artifacts_dir is not None:
        payload["artifacts_dir"] = str(artifacts_dir)
    return payload


def _unavailable_case(template_id: str) -> JsonObject:
    return {
        "template_id": template_id,
        "status": "stata_unavailable",
        "missing_deps": ["stata"],
    }


def _safe_child_path(*, parent: Path, rel_path: str) -> Path | None:
    candidate = (parent / rel_path).resolve()
    if not candidate.is_relative_to(parent.resolve()):
        return None
    return candidate


def _stage_fixtures(
    *, library_dir: Path, work_dir: Path, template: SmokeSuiteTemplate
) -> None:
    work_dir.mkdir(parents=True, exist_ok=True)
    for fixture in template.fixtures:
        source_path = _safe_child_path(parent=library_dir, rel_path=fixture.source)
        if source_path is None or not source_path.is_file():
            raise SSError(
                error_code="SMOKE_SUITE_FIXTURE_NOT_FOUND",
                message=f"fixture not found: {fixture.source}",
            )
        dest_path = work_dir / fixture.dest
        try:
            shutil.copy2(source_path, dest_path)
        except OSError as e:
            raise SSError(
                error_code="SMOKE_SUITE_FIXTURE_COPY_FAILED",
                message=f"fixture copy failed: {fixture.source} -> {fixture.dest} ({e})",
            ) from e


def _load_run_meta(*, artifacts_dir: Path) -> tuple[tuple[str, ...], tuple[str, ...]]:
    path = artifacts_dir / "do_template_run.meta.json"
    if not path.exists():
        return tuple(), tuple()
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return tuple(), tuple()
    if not isinstance(raw, dict):
        return tuple(), tuple()

    archived_outputs = raw.get("archived_outputs", [])
    missing_outputs = raw.get("missing_outputs", [])
    if not isinstance(archived_outputs, list) or not isinstance(missing_outputs, list):
        return tuple(), tuple()

    archived = tuple(str(x) for x in archived_outputs if isinstance(x, str) and x.strip() != "")
    missing = tuple(str(x) for x in missing_outputs if isinstance(x, str) and x.strip() != "")
    return archived, missing


def _extract_missing_deps(*, artifacts_dir: Path) -> tuple[str, ...]:
    candidates = (
        artifacts_dir / "outputs" / "result.log",
        artifacts_dir / "stata.log",
        artifacts_dir / "run.stdout",
    )
    deps: list[str] = []
    for path in candidates:
        if not path.exists():
            continue
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        for line in text.splitlines():
            stripped = line.strip()
            m = _DEP_MISSING.match(stripped)
            if m is not None:
                pkg = m.group("pkg")
                if isinstance(pkg, str):
                    deps.append(pkg)
                continue
            m = _DEP_CHECK_MISSING.match(stripped)
            if m is not None:
                pkg = m.group("pkg")
                if isinstance(pkg, str):
                    deps.append(pkg)
    return tuple(sorted(set(d for d in deps if isinstance(d, str) and d.strip() != "")))


def _case_result(
    template: SmokeSuiteTemplate,
    job_id: str,
    run_id: str,
    artifacts_dir: Path,
    result: RunResult,
) -> JsonObject:
    missing_deps = _extract_missing_deps(artifacts_dir=artifacts_dir)
    archived_outputs, missing_outputs = _load_run_meta(artifacts_dir=artifacts_dir)

    if missing_deps:
        status = "missing_deps"
    else:
        status = "passed" if result.ok else "failed"

    payload: JsonObject = {
        "template_id": template.template_id,
        "status": status,
        "job_id": job_id,
        "run_id": run_id,
        "exit_code": result.exit_code,
        "timed_out": result.timed_out,
        "missing_deps": list(missing_deps),
        "archived_outputs": list(archived_outputs),
        "missing_outputs": list(missing_outputs),
        "artifacts_dir": str(artifacts_dir),
    }
    if result.error is not None:
        payload["error"] = {
            "error_code": result.error.error_code,
            "message": result.error.message,
        }
    return payload


def _run_template_case(
    *,
    manifest: SmokeSuiteManifest,
    template: SmokeSuiteTemplate,
    library_dir: Path,
    job_service: JobService,
    template_runner: DoTemplateRunService,
    timeout_seconds: int | None,
) -> JsonObject:
    job = job_service.create_job(
        tenant_id=DEFAULT_TENANT_ID,
        requirement=f"smoke_suite:{manifest.suite_id}:{template.template_id}",
        plan_revision=uuid.uuid4().hex,
    )
    run_id = uuid.uuid4().hex
    dirs = resolve_run_dirs(
        jobs_dir=template_runner.jobs_dir,
        tenant_id=DEFAULT_TENANT_ID,
        job_id=job.job_id,
        run_id=run_id,
    )
    if dirs is None:
        return _error_case(
            template.template_id,
            "SMOKE_SUITE_RUN_DIRS_INVALID",
            "invalid job/run workspace",
        )

    try:
        _stage_fixtures(library_dir=library_dir, work_dir=dirs.work_dir, template=template)
        result = template_runner.run(
            tenant_id=DEFAULT_TENANT_ID,
            job_id=job.job_id,
            template_id=template.template_id,
            params=template.params,
            timeout_seconds=timeout_seconds,
            run_id=run_id,
        )
    except SSError as e:
        return _error_case(
            template.template_id,
            e.error_code,
            e.message,
            job_id=job.job_id,
            run_id=run_id,
            artifacts_dir=dirs.artifacts_dir,
        )

    return _case_result(template, job.job_id, run_id, dirs.artifacts_dir, result)


def _summarize(*, cases: Sequence[JsonObject]) -> JsonObject:
    summary: dict[str, int] = {}
    for item in cases:
        status = item.get("status", "")
        if not isinstance(status, str) or status.strip() == "":
            continue
        summary[status] = summary.get(status, 0) + 1
    return cast(JsonObject, summary)


def run_smoke_suite(
    *,
    manifest: SmokeSuiteManifest,
    library_dir: Path,
    job_service: JobService | None,
    template_runner: DoTemplateRunService | None,
    stata_cmd: Sequence[str] | None,
    timeout_seconds: int | None,
) -> JsonObject:
    started_at = utc_now().isoformat()
    templates = [manifest.templates[k] for k in sorted(manifest.templates.keys())]

    cases: list[JsonObject] = []
    for template in templates:
        if job_service is None or template_runner is None or not stata_cmd:
            cases.append(_unavailable_case(template.template_id))
            continue
        cases.append(
            _run_template_case(
                manifest=manifest,
                template=template,
                library_dir=library_dir,
                job_service=job_service,
                template_runner=template_runner,
                timeout_seconds=timeout_seconds,
            )
        )

    return {
        "schema_version": "1.0",
        "suite_id": manifest.suite_id,
        "started_at": started_at,
        "finished_at": utc_now().isoformat(),
        "library_dir": str(library_dir),
        "stata_cmd": list(stata_cmd) if stata_cmd else [],
        "summary": _summarize(cases=cases),
        "cases": cast(list[JsonValue], cases),
    }
