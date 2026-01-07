from __future__ import annotations

import uuid
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Callable

from src.domain.do_template_rendering import render_do_text, template_param_specs
from src.domain.do_template_repository import DoTemplate, DoTemplateRepository
from src.domain.do_template_run_evidence import (
    archive_outputs,
    write_run_meta,
    write_template_evidence,
)
from src.domain.do_template_run_support import append_artifact_if_missing, ensure_job_status
from src.domain.job_store import JobStore
from src.domain.models import ArtifactRef, Job, JobStatus, RunAttempt
from src.domain.stata_runner import RunResult, StataRunner
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import DoTemplateContractInvalidError, SSError
from src.infra.stata_run_support import RunDirs, resolve_run_dirs
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now


@dataclass(frozen=True)
class DoTemplateRunService:
    store: JobStore
    runner: StataRunner
    repo: DoTemplateRepository
    state_machine: JobStateMachine
    jobs_dir: Path
    clock: Callable[[], datetime] = utc_now

    def run(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        template_id: str,
        params: dict[str, str],
        timeout_seconds: int | None = None,
        run_id: str | None = None,
    ) -> RunResult:
        run_id_final, dirs = self._init_run(
            tenant_id=tenant_id,
            job_id=job_id,
            template_id=template_id,
            run_id=run_id,
        )
        try:
            return self._run_attempt(
                tenant_id=tenant_id,
                job_id=job_id,
                run_id=run_id_final,
                template_id=template_id,
                params=params,
                timeout_seconds=timeout_seconds,
                dirs=dirs,
            )
        except SSError:
            self._finalize_job(
                tenant_id=tenant_id,
                job_id=job_id,
                run_id=run_id_final,
                artifacts=tuple(),
                ok=False,
            )
            raise

    def _run_attempt(
        self,
        *,
        tenant_id: str,
        job_id: str,
        run_id: str,
        template_id: str,
        params: dict[str, str],
        timeout_seconds: int | None,
        dirs: RunDirs,
    ) -> RunResult:
        template, rendered_do, resolved_params = self._load_and_render_template(
            template_id=template_id,
            params=params,
        )
        template_refs = write_template_evidence(
            job_id=job_id,
            run_id=run_id,
            template_id=template_id,
            raw_do=template.do_text,
            meta=template.meta,
            params=resolved_params,
            artifacts_dir=dirs.artifacts_dir,
            job_dir=dirs.job_dir,
        )
        result = self.runner.run(
            tenant_id=tenant_id,
            job_id=job_id,
            run_id=run_id,
            do_file=rendered_do,
            timeout_seconds=timeout_seconds,
        )
        run_meta_ref, output_refs = self._archive_and_write_meta(
            job_id=job_id,
            run_id=run_id,
            template_id=template_id,
            params=resolved_params,
            meta=template.meta,
            work_dir=dirs.work_dir,
            artifacts_dir=dirs.artifacts_dir,
            job_dir=dirs.job_dir,
        )
        combined = (*template_refs, run_meta_ref, *output_refs, *result.artifacts)
        self._finalize_job(
            tenant_id=tenant_id,
            job_id=job_id,
            run_id=run_id,
            artifacts=combined,
            ok=result.ok,
        )
        return self._result_with_artifacts(result=result, artifacts=combined)

    def _archive_and_write_meta(
        self,
        *,
        job_id: str,
        run_id: str,
        template_id: str,
        params: dict[str, str],
        meta: JsonObject,
        work_dir: Path,
        artifacts_dir: Path,
        job_dir: Path,
    ) -> tuple[ArtifactRef, tuple[ArtifactRef, ...]]:
        output_refs, missing = archive_outputs(
            template_id=template_id,
            meta=meta,
            work_dir=work_dir,
            artifacts_dir=artifacts_dir,
            job_dir=job_dir,
        )
        run_meta_ref = write_run_meta(
            job_id=job_id,
            run_id=run_id,
            template_id=template_id,
            params=params,
            archived_outputs=output_refs,
            missing_outputs=missing,
            artifacts_dir=artifacts_dir,
            job_dir=job_dir,
        )
        return run_meta_ref, output_refs

    def _result_with_artifacts(
        self,
        *,
        result: RunResult,
        artifacts: tuple[ArtifactRef, ...],
    ) -> RunResult:
        return RunResult(
            job_id=result.job_id,
            run_id=result.run_id,
            ok=result.ok,
            exit_code=result.exit_code,
            timed_out=result.timed_out,
            artifacts=artifacts,
            error=result.error,
        )

    def _init_run(
        self,
        *,
        tenant_id: str,
        job_id: str,
        template_id: str,
        run_id: str | None,
    ) -> tuple[str, RunDirs]:
        job = self.store.load(tenant_id=tenant_id, job_id=job_id)
        self._ensure_queued(job_id=job_id, job=job, template_id=template_id)

        run_id_final = run_id if run_id is not None else uuid.uuid4().hex
        dirs = resolve_run_dirs(
            jobs_dir=self.jobs_dir,
            tenant_id=tenant_id,
            job_id=job_id,
            run_id=run_id_final,
        )
        if dirs is None:
            raise DoTemplateContractInvalidError(template_id=template_id, reason="run_dirs_invalid")
        dirs.work_dir.mkdir(parents=True, exist_ok=True)
        dirs.artifacts_dir.mkdir(parents=True, exist_ok=True)

        ensure_job_status(
            job_id=job_id,
            state_machine=self.state_machine,
            job=job,
            status=JobStatus.RUNNING,
        )
        job.runs.append(
            RunAttempt(
                run_id=run_id_final,
                attempt=1,
                status=JobStatus.RUNNING.value,
                started_at=self.clock().isoformat(),
            )
        )
        self.store.save(tenant_id=tenant_id, job=job)
        return run_id_final, dirs

    def _load_and_render_template(
        self, *, template_id: str, params: dict[str, str]
    ) -> tuple[DoTemplate, str, dict[str, str]]:
        template = self.repo.get_template(template_id=template_id)
        specs = template_param_specs(template_id=template_id, meta=template.meta)
        rendered_do, resolved_params = render_do_text(
            template_id=template_id,
            do_text=template.do_text,
            specs=specs,
            params=params,
        )
        return template, rendered_do, resolved_params

    def _ensure_queued(self, *, job_id: str, job: Job, template_id: str) -> None:
        if job.status == JobStatus.CREATED:
            ensure_job_status(
                job_id=job_id,
                state_machine=self.state_machine,
                job=job,
                status=JobStatus.DRAFT_READY,
            )
        if job.status == JobStatus.DRAFT_READY:
            ensure_job_status(
                job_id=job_id,
                state_machine=self.state_machine,
                job=job,
                status=JobStatus.CONFIRMED,
            )
        if job.status == JobStatus.CONFIRMED:
            ensure_job_status(
                job_id=job_id,
                state_machine=self.state_machine,
                job=job,
                status=JobStatus.QUEUED,
            )
        if job.status != JobStatus.QUEUED:
            raise DoTemplateContractInvalidError(
                template_id=template_id,
                reason=f"job_status_not_runnable:{job.status.value}",
            )
        self.store.save(tenant_id=job.tenant_id, job=job)

    def _finalize_job(
        self,
        *,
        tenant_id: str,
        job_id: str,
        run_id: str,
        artifacts: tuple[ArtifactRef, ...],
        ok: bool,
    ) -> None:
        job = self.store.load(tenant_id=tenant_id, job_id=job_id)
        status = JobStatus.SUCCEEDED if ok else JobStatus.FAILED
        ensure_job_status(job_id=job_id, state_machine=self.state_machine, job=job, status=status)

        ended = self.clock().isoformat()
        for attempt in reversed(job.runs):
            if attempt.run_id != run_id:
                continue
            attempt.status = status.value
            attempt.ended_at = ended
            for ref in artifacts:
                append_artifact_if_missing(refs=attempt.artifacts, ref=ref)
            break

        for ref in artifacts:
            append_artifact_if_missing(refs=job.artifacts_index, ref=ref)
        self.store.save(tenant_id=tenant_id, job=job)
