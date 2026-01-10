from __future__ import annotations

import logging
from pathlib import Path
from typing import Sequence

from src.domain.models import is_safe_job_rel_path
from src.domain.stata_runner import RunError, RunResult, StataRunner
from src.infra.stata_run_support import (
    DO_FILENAME,
    Execution,
    RunDirs,
    artifact_refs,
    job_rel_path,
    meta_payload,
    resolve_run_dirs,
    result_without_artifacts,
    write_run_artifacts,
    write_text,
)
from src.infra.stata_safety import copy_inputs_dir
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class FakeStataRunner(StataRunner):
    def __init__(
        self,
        *,
        jobs_dir: Path,
        scripted_ok: Sequence[bool] | None = None,
    ) -> None:
        self._jobs_dir = Path(jobs_dir)
        self._scripted_ok = list(scripted_ok) if scripted_ok is not None else None
        self._cursor = 0

    def run(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
        inputs_dir_rel: str | None = None,
    ) -> RunResult:
        dirs = resolve_run_dirs(
            jobs_dir=self._jobs_dir,
            tenant_id=tenant_id,
            job_id=job_id,
            run_id=run_id,
        )
        if dirs is None:
            logger.warning(
                "SS_FAKE_STATA_INVALID_WORKSPACE",
                extra={"tenant_id": tenant_id, "job_id": job_id, "run_id": run_id},
            )
            return result_without_artifacts(
                job_id=job_id,
                run_id=run_id,
                error_code="STATA_WORKSPACE_INVALID",
                message="invalid job_id/run_id workspace",
            )

        ok = self._next_ok()
        execution = self._execution_for(ok=ok)
        do_artifact_path = self._write_workspace_files(
            dirs=dirs,
            job_id=job_id,
            run_id=run_id,
            do_file=do_file,
            inputs_dir_rel=inputs_dir_rel,
        )
        if isinstance(do_artifact_path, RunResult):
            return do_artifact_path
        if ok:
            self._write_fake_outputs(dirs=dirs, job_id=job_id, run_id=run_id)

        meta = self._meta_for(
            dirs=dirs,
            job_id=job_id,
            run_id=run_id,
            timeout_seconds=timeout_seconds,
            execution=execution,
        )
        written = self._write_run_artifacts(
            dirs=dirs,
            job_id=job_id,
            run_id=run_id,
            meta=meta,
            execution=execution,
        )
        if isinstance(written, RunResult):
            return written
        return self._build_result(
            dirs=dirs,
            job_id=job_id,
            run_id=run_id,
            do_artifact_path=do_artifact_path,
            execution=execution,
            written=written,
        )

    def _next_ok(self) -> bool:
        if self._scripted_ok is None:
            return True
        if self._cursor >= len(self._scripted_ok):
            return bool(self._scripted_ok[-1])
        ok = bool(self._scripted_ok[self._cursor])
        self._cursor += 1
        return ok

    def _execution_for(self, *, ok: bool) -> Execution:
        if ok:
            return Execution(
                stdout_text="fake stdout\n",
                stderr_text="",
                exit_code=0,
                timed_out=False,
                duration_ms=0,
                error=None,
            )
        error = RunError(error_code="FAKE_STATA_ERROR", message="fake stata failure")
        return Execution(
            stdout_text="fake stdout\n",
            stderr_text=error.message,
            exit_code=1,
            timed_out=False,
            duration_ms=0,
            error=error,
        )

    def _write_workspace_files(
        self,
        *,
        dirs: RunDirs,
        job_id: str,
        run_id: str,
        do_file: str,
        inputs_dir_rel: str | None,
    ) -> Path | RunResult:
        dirs.work_dir.mkdir(parents=True, exist_ok=True)
        dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
        try:
            source_dir = self._inputs_source_dir(
                job_dir=dirs.job_dir,
                inputs_dir_rel=inputs_dir_rel,
            )
            if source_dir is None:
                return result_without_artifacts(
                    job_id=job_id,
                    run_id=run_id,
                    error_code="STATA_INPUTS_UNSAFE",
                    message="inputs_dir_rel unsafe",
                )
            copy_inputs_dir(source_dir=source_dir, work_dir=dirs.work_dir)
        except OSError as e:
            logger.warning(
                "SS_FAKE_STATA_COPY_INPUTS_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
            )
            return result_without_artifacts(
                job_id=job_id,
                run_id=run_id,
                error_code="STATA_INPUTS_COPY_FAILED",
                message=str(e),
            )

        do_work_path = dirs.work_dir / DO_FILENAME
        do_artifact_path = dirs.artifacts_dir / DO_FILENAME
        try:
            write_text(do_work_path, do_file)
            write_text(do_artifact_path, do_file)
        except OSError as e:
            logger.warning(
                "SS_FAKE_STATA_WRITE_DOFILE_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "path": str(do_work_path)},
            )
            return result_without_artifacts(
                job_id=job_id,
                run_id=run_id,
                error_code="STATA_DOFILE_WRITE_FAILED",
                message=str(e),
            )
        return do_artifact_path

    def _write_fake_outputs(self, *, dirs: RunDirs, job_id: str, run_id: str) -> None:
        try:
            write_text(dirs.work_dir / "result.log", "fake template result\n")
            write_text(dirs.work_dir / "table_T01_desc_stats.csv", "metric,value\nN,1\n")
            write_text(dirs.work_dir / "table_T01_missing_pattern.csv", "metric,value\nk,2\n")
            write_text(dirs.work_dir / "table_TA14_quality_summary.csv", "metric,value\nN,1\n")
            write_text(dirs.work_dir / "table_TA14_var_diagnostics.csv", "var,ok\nx,1\n")
            write_text(dirs.work_dir / "table_TA14_issues.csv", "issue\nnone\n")
            write_text(dirs.work_dir / "fig_TA14_quality_heatmap.png", "not-a-real-png\n")
        except OSError as e:
            logger.warning(
                "SS_FAKE_STATA_WRITE_OUTPUTS_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
            )

    def _inputs_source_dir(self, *, job_dir: Path, inputs_dir_rel: str | None) -> Path | None:
        if inputs_dir_rel is None:
            return job_dir / "inputs"
        if inputs_dir_rel.strip() == "" or not is_safe_job_rel_path(inputs_dir_rel):
            return None
        base = job_dir.resolve(strict=False)
        path = (job_dir / inputs_dir_rel).resolve(strict=False)
        if not path.is_relative_to(base):
            return None
        return path

    def _meta_for(
        self,
        *,
        dirs: RunDirs,
        job_id: str,
        run_id: str,
        timeout_seconds: int | None,
        execution: Execution,
    ) -> JsonObject:
        return meta_payload(
            job_id=job_id,
            run_id=run_id,
            cmd=["fake-stata", "-b", "do", DO_FILENAME],
            cwd_rel=job_rel_path(job_dir=dirs.job_dir, path=dirs.work_dir),
            timeout_seconds=timeout_seconds,
            execution=execution,
        )

    def _write_run_artifacts(
        self,
        *,
        dirs: RunDirs,
        job_id: str,
        run_id: str,
        meta: JsonObject,
        execution: Execution,
    ) -> tuple[Path, Path, Path, Path, Path] | RunResult:
        try:
            return write_run_artifacts(
                artifacts_dir=dirs.artifacts_dir,
                stdout_text=execution.stdout_text,
                stderr_text=execution.stderr_text,
                meta=meta,
                error=execution.error,
                exit_code=execution.exit_code,
                timed_out=execution.timed_out,
            )
        except OSError as e:
            logger.warning(
                "SS_FAKE_STATA_WRITE_ARTIFACTS_FAILED",
                extra={"job_id": job_id, "run_id": run_id, "reason": str(e)},
            )
            return result_without_artifacts(
                job_id=job_id,
                run_id=run_id,
                error_code="STATA_ARTIFACTS_WRITE_FAILED",
                message=str(e),
            )

    def _build_result(
        self,
        *,
        dirs: RunDirs,
        job_id: str,
        run_id: str,
        do_artifact_path: Path,
        execution: Execution,
        written: tuple[Path, Path, Path, Path, Path],
    ) -> RunResult:
        artifacts = artifact_refs(
            job_dir=dirs.job_dir,
            do_artifact_path=do_artifact_path,
            stdout_path=written[0],
            stderr_path=written[1],
            log_path=written[2],
            meta_path=written[3],
            error_path=written[4],
            include_error=execution.error is not None,
        )
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=execution.error is None,
            exit_code=execution.exit_code,
            timed_out=execution.timed_out,
            artifacts=artifacts,
            error=execution.error,
        )
