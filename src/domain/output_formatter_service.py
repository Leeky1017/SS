from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.models import ArtifactKind, ArtifactRef, Job
from src.domain.output_formats import normalize_output_formats
from src.domain.output_formatter_data import produce_csv, produce_dta
from src.domain.output_formatter_error import write_run_error_artifact
from src.domain.output_formatter_excel import produce_xlsx
from src.domain.output_formatter_reports import produce_docx, produce_pdf
from src.domain.output_formatter_support import formats_present
from src.domain.stata_runner import RunError
from src.infra.exceptions import OutputFormatsInvalidError
from src.infra.stata_run_support import resolve_run_dirs
from src.utils.time import utc_now


@dataclass(frozen=True)
class OutputFormatterOutcome:
    artifacts: tuple[ArtifactRef, ...]
    error: RunError | None = None


@dataclass(frozen=True)
class OutputFormatterService:
    jobs_dir: Path
    clock: Callable[[], datetime] = utc_now

    def format_run_outputs(
        self,
        *,
        job: Job,
        run_id: str,
        artifacts: tuple[ArtifactRef, ...],
    ) -> OutputFormatterOutcome:
        dirs = resolve_run_dirs(
            jobs_dir=Path(self.jobs_dir),
            tenant_id=job.tenant_id,
            job_id=job.job_id,
            run_id=run_id,
        )
        if dirs is None:
            return OutputFormatterOutcome(
                artifacts=tuple(),
                error=RunError(
                    error_code="STATA_WORKSPACE_INVALID",
                    message="invalid job/run workspace",
                ),
            )

        try:
            requested = normalize_output_formats(job.output_formats)
        except OutputFormatsInvalidError as e:
            return self._fail_with_error(
                job=job,
                job_dir=dirs.job_dir,
                artifacts_dir=dirs.artifacts_dir,
                error=RunError(error_code=e.error_code, message=e.message),
            )

        present = formats_present(artifacts=artifacts)
        missing = [
            fmt
            for fmt in requested
            if not self._is_format_satisfied(fmt=fmt, present=present, artifacts=artifacts)
        ]
        if not missing:
            return OutputFormatterOutcome(artifacts=tuple())

        created_at = self.clock().isoformat()
        formatted_dir = dirs.artifacts_dir / "formatted"
        new_refs: list[ArtifactRef] = []
        for fmt in missing:
            ref, err = self._produce_one(
                fmt=fmt,
                created_at=created_at,
                job=job,
                job_dir=dirs.job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
            if err is not None:
                return self._fail_with_error(
                    job=job,
                    job_dir=dirs.job_dir,
                    artifacts_dir=dirs.artifacts_dir,
                    error=err,
                    extra_artifacts=tuple(new_refs),
                )
            if ref is not None:
                new_refs.append(ref)

        return OutputFormatterOutcome(artifacts=tuple(new_refs))

    def _is_format_satisfied(
        self,
        *,
        fmt: str,
        present: set[str],
        artifacts: tuple[ArtifactRef, ...],
    ) -> bool:
        if fmt in {"docx", "pdf"}:
            return any(
                ref.kind == ArtifactKind.STATA_EXPORT_REPORT
                and ref.rel_path.lower().endswith(f".{fmt}")
                for ref in artifacts
            )
        return fmt in present

    def _produce_one(
        self,
        *,
        fmt: str,
        created_at: str,
        job: Job,
        job_dir: Path,
        formatted_dir: Path,
        artifacts: tuple[ArtifactRef, ...],
    ) -> tuple[ArtifactRef | None, RunError | None]:
        if fmt in {"log", "do"}:
            return None, RunError(
                error_code="OUTPUT_FORMATTER_FAILED",
                message=f"requested format missing from artifacts: {fmt}",
            )
        if fmt == "xlsx":
            return produce_xlsx(
                created_at=created_at,
                job_dir=job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
        if fmt == "dta":
            return produce_dta(
                created_at=created_at,
                job_dir=job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
        if fmt == "csv":
            return produce_csv(
                created_at=created_at,
                job_dir=job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
        if fmt == "docx":
            return produce_docx(
                created_at=created_at,
                job_id=job.job_id,
                job_dir=job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
        if fmt == "pdf":
            return produce_pdf(
                created_at=created_at,
                job_id=job.job_id,
                job_dir=job_dir,
                formatted_dir=formatted_dir,
                artifacts=artifacts,
            )
        return None, RunError(
            error_code="OUTPUT_FORMATTER_FAILED",
            message=f"unsupported format: {fmt}",
        )

    def _fail_with_error(
        self,
        *,
        job: Job,
        job_dir: Path,
        artifacts_dir: Path,
        error: RunError,
        extra_artifacts: tuple[ArtifactRef, ...] = tuple(),
    ) -> OutputFormatterOutcome:
        error_ref = write_run_error_artifact(
            job_dir=job_dir,
            artifacts_dir=artifacts_dir,
            error=error,
        )
        artifacts: tuple[ArtifactRef, ...] = extra_artifacts
        if error_ref is not None:
            artifacts = (*artifacts, error_ref)
        return OutputFormatterOutcome(artifacts=artifacts, error=error)
