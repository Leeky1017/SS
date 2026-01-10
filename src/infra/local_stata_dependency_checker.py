from __future__ import annotations

import logging
import re
import subprocess
from pathlib import Path
from typing import Callable, Sequence

from src.domain.stata_dependency_checker import (
    StataDependency,
    StataDependencyChecker,
    StataDependencyCheckResult,
)
from src.domain.stata_runner import RunError
from src.infra.stata_cmd import build_stata_batch_cmd
from src.infra.stata_run_support import RunDirs, resolve_run_dirs
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)

_SAFE_STATA_NAME_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")

_CHECKABLE_SOURCES = {"ssc", "ado"}


def _is_safe_stata_name(value: str) -> bool:
    return bool(_SAFE_STATA_NAME_RE.fullmatch(value))


def _preflight_do_file(*, packages: Sequence[str], out_filename: str) -> str:
    quoted = " ".join(packages)
    return "\n".join(
        [
            'capture log close _all',
            "set more off",
            f'file open fh using "{out_filename}", write text replace',
            f"foreach pkg in {quoted} {{",
            "  capture which `pkg'",
            "  if _rc != 0 {",
            "    file write fh \"`pkg'\" _n",
            "  }",
            "}",
            "file close fh",
            "exit, clear",
            "",
        ]
    )


def _split_dependencies(
    dependencies: Sequence[StataDependency],
) -> tuple[list[StataDependency], list[StataDependency]]:
    to_check: list[StataDependency] = []
    invalid: list[StataDependency] = []
    for dep in dependencies:
        if dep.source not in _CHECKABLE_SOURCES:
            continue
        if not _is_safe_stata_name(dep.pkg):
            invalid.append(dep)
            continue
        to_check.append(dep)
    return to_check, invalid


def _resolve_dirs_or_error(
    *,
    jobs_dir: Path,
    tenant_id: str,
    job_id: str,
    run_id: str,
) -> tuple[RunDirs | None, RunError | None]:
    dirs = resolve_run_dirs(
        jobs_dir=jobs_dir,
        tenant_id=tenant_id,
        job_id=job_id,
        run_id=run_id,
    )
    if dirs is None:
        return None, RunError(
            error_code="STATA_WORKSPACE_INVALID",
            message="invalid job_id/run_id workspace",
        )
    return dirs, None


def _write_preflight_files(
    *,
    work_dir: Path,
    packages: Sequence[str],
) -> tuple[str, Path, RunError | None]:
    do_filename = "dependency_preflight.do"
    out_filename = "dependency_preflight.missing.txt"
    do_path = work_dir / do_filename
    out_path = work_dir / out_filename
    try:
        do_path.write_text(
            _preflight_do_file(packages=packages, out_filename=out_filename),
            encoding="utf-8",
        )
    except OSError as e:
        return do_filename, out_path, RunError(
            error_code="STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED",
            message=str(e),
        )
    return do_filename, out_path, None


def _run_preflight_or_error(
    *,
    work_dir: Path,
    stata_cmd: Sequence[str],
    do_filename: str,
    subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None,
    timeout_seconds: int,
) -> RunError | None:
    cmd = build_stata_batch_cmd(stata_cmd=stata_cmd, do_filename=do_filename)
    run = subprocess.run if subprocess_runner is None else subprocess_runner
    try:
        completed = run(
            cmd,
            cwd=str(work_dir),
            timeout=timeout_seconds,
            text=True,
            capture_output=True,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return RunError(
            error_code="STATA_DEPENDENCY_PREFLIGHT_TIMEOUT",
            message="dependency preflight timed out",
        )
    except OSError as e:
        return RunError(
            error_code="STATA_DEPENDENCY_PREFLIGHT_SUBPROCESS_FAILED",
            message=str(e),
        )
    if int(completed.returncode) != 0:
        return RunError(
            error_code="STATA_DEPENDENCY_PREFLIGHT_FAILED",
            message=f"dependency preflight exited with code {int(completed.returncode)}",
        )
    return None


def _read_missing_packages_or_error(*, path: Path) -> tuple[set[str], RunError | None]:
    missing_pkgs: set[str] = set()
    try:
        if not path.is_file():
            return missing_pkgs, None
        for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
            pkg = line.strip()
            if pkg != "":
                missing_pkgs.add(pkg)
    except OSError as e:
        return missing_pkgs, RunError(
            error_code="STATA_DEPENDENCY_PREFLIGHT_READ_FAILED",
            message=str(e),
        )
    return missing_pkgs, None


class LocalStataDependencyChecker(StataDependencyChecker):
    def __init__(
        self,
        *,
        jobs_dir: Path,
        stata_cmd: Sequence[str],
        subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None = None,
    ) -> None:
        self._jobs_dir = Path(jobs_dir)
        self._stata_cmd = list(stata_cmd)
        self._subprocess_runner = subprocess_runner

    def check(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        run_id: str,
        dependencies: Sequence[StataDependency],
    ) -> StataDependencyCheckResult:
        to_check, invalid = _split_dependencies(dependencies)
        if not to_check and not invalid:
            return StataDependencyCheckResult()
        dirs, dirs_error = _resolve_dirs_or_error(
            jobs_dir=self._jobs_dir,
            tenant_id=tenant_id,
            job_id=job_id,
            run_id=run_id,
        )
        if dirs_error is not None:
            return StataDependencyCheckResult(error=dirs_error)
        if dirs is None:
            return StataDependencyCheckResult(
                error=RunError(
                    error_code="STATA_WORKSPACE_INVALID",
                    message="invalid job_id/run_id workspace",
                )
            )
        work_dir = dirs.work_dir
        work_dir.mkdir(parents=True, exist_ok=True)

        do_filename, out_path, write_error = _write_preflight_files(
            work_dir=work_dir,
            packages=[dep.pkg for dep in to_check],
        )
        if write_error is not None:
            logger.warning(
                "SS_STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "reason": write_error.message},
            )
            return StataDependencyCheckResult(error=write_error)

        run_error = _run_preflight_or_error(
            work_dir=work_dir,
            stata_cmd=self._stata_cmd,
            do_filename=do_filename,
            subprocess_runner=self._subprocess_runner,
            timeout_seconds=60,
        )
        if run_error is not None:
            logger.warning(
                "SS_STATA_DEPENDENCY_PREFLIGHT_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "error_code": run_error.error_code},
            )
            return StataDependencyCheckResult(error=run_error)

        missing_pkgs, read_error = _read_missing_packages_or_error(path=out_path)
        if read_error is not None:
            logger.warning(
                "SS_STATA_DEPENDENCY_PREFLIGHT_READ_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "reason": read_error.message},
            )
            return StataDependencyCheckResult(error=read_error)

        missing: list[StataDependency] = list(invalid)
        for dep in to_check:
            if dep.pkg in missing_pkgs:
                missing.append(dep)
        return StataDependencyCheckResult(missing=tuple(missing))
