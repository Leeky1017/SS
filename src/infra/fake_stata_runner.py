from __future__ import annotations

import logging
from pathlib import Path
from typing import Sequence

from opentelemetry import trace

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
from src.utils.json_types import JsonObject

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
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ) -> RunResult:
        tracer = trace.get_tracer(__name__)
        with tracer.start_as_current_span("ss.stata.run") as span:
            span.set_attribute("ss.job_id", job_id)
            span.set_attribute("ss.run_id", run_id)
            if timeout_seconds is not None:
                span.set_attribute("ss.timeout_seconds", timeout_seconds)
            result = self._run_impl(
                job_id=job_id,
                run_id=run_id,
                do_file=do_file,
                timeout_seconds=timeout_seconds,
            )
            span.set_attribute("ss.ok", result.ok)
            span.set_attribute("ss.exit_code", result.exit_code)
            return result

    def _run_impl(
        self,
        *,
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None,
    ) -> RunResult:
        resolved = self._resolve_dirs(job_id=job_id, run_id=run_id)
        if isinstance(resolved, RunResult):
            return resolved

        ok = self._next_ok()
        execution = self._execution_for(ok=ok)

        do_artifact_path = self._write_do_files(
            dirs=resolved,
            job_id=job_id,
            run_id=run_id,
            do_file=do_file,
        )
        if isinstance(do_artifact_path, RunResult):
            return do_artifact_path

        meta = self._meta_for(
            dirs=resolved,
            job_id=job_id,
            run_id=run_id,
            timeout_seconds=timeout_seconds,
            execution=execution,
        )
        written = self._write_run_artifacts(
            dirs=resolved,
            job_id=job_id,
            run_id=run_id,
            meta=meta,
            execution=execution,
        )
        if isinstance(written, RunResult):
            return written
        return self._build_result(
            dirs=resolved,
            job_id=job_id,
            run_id=run_id,
            do_artifact_path=do_artifact_path,
            execution=execution,
            written=written,
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
        stdout_path, stderr_path, log_path, meta_path, error_path = written
        artifacts = artifact_refs(
            job_dir=dirs.job_dir,
            do_artifact_path=do_artifact_path,
            stdout_path=stdout_path,
            stderr_path=stderr_path,
            log_path=log_path,
            meta_path=meta_path,
            error_path=error_path,
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

    def _next_ok(self) -> bool:
        if self._scripted_ok is None:
            return True
        if self._cursor >= len(self._scripted_ok):
            return self._scripted_ok[-1]
        ok = bool(self._scripted_ok[self._cursor])
        self._cursor += 1
        return ok

    def _resolve_dirs(self, *, job_id: str, run_id: str) -> RunDirs | RunResult:
        dirs = resolve_run_dirs(jobs_dir=self._jobs_dir, job_id=job_id, run_id=run_id)
        if dirs is not None:
            return dirs
        logger.warning(
            "SS_FAKE_STATA_INVALID_WORKSPACE",
            extra={"job_id": job_id, "run_id": run_id},
        )
        return result_without_artifacts(
            job_id=job_id,
            run_id=run_id,
            error_code="STATA_WORKSPACE_INVALID",
            message="invalid job_id/run_id workspace",
        )

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

    def _write_do_files(
        self,
        *,
        dirs: RunDirs,
        job_id: str,
        run_id: str,
        do_file: str,
    ) -> Path | RunResult:
        dirs.work_dir.mkdir(parents=True, exist_ok=True)
        dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)
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
