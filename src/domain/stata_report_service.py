"""Service for generating Stata result interpretation reports.

Orchestrates: extract numbers → build prompt → call LLM → parse → write artifacts.
"""

from __future__ import annotations

import logging
from pathlib import Path

from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, ArtifactRef, Job
from src.domain.stata_report_llm import build_stata_report_prompt, parse_stata_report
from src.domain.stata_report_models import (
    MainResultSummary,
    ReportGenerationOutcome,
    StataReportInput,
    StataReportParseError,
    StataReportResult,
)
from src.domain.stata_result_parser import (
    StataResultParseError,
    extract_main_result_from_artifact,
)
from src.infra.exceptions import JobStoreIOError, LLMArtifactsWriteError, LLMCallFailedError
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


class StataReportService:
    """Service for generating LLM-interpreted Stata result reports."""

    def __init__(
        self,
        *,
        store: JobStore,
        llm: LLMClient,
        workspace: JobWorkspaceStore,
    ):
        self._store = store
        self._llm = llm
        self._workspace = workspace

    async def generate_report(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        table_rel_path: str,
        log_rel_path: str | None = None,
    ) -> ReportGenerationOutcome:
        """Generate an interpretation report for a Stata export table artifact."""
        logger.info(
            "SS_STATA_REPORT_START",
            extra={"tenant_id": tenant_id, "job_id": job_id, "table_rel_path": table_rel_path},
        )
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        main_result, error = self._try_extract_results(
            tenant_id=tenant_id,
            job_id=job_id,
            table_rel_path=table_rel_path,
            log_rel_path=log_rel_path,
        )
        if error is not None:
            return ReportGenerationOutcome(success=False, error_message=error)
        assert main_result is not None
        input_data = self._build_report_input(job=job, main_result=main_result)
        prompt = build_stata_report_prompt(input_data)
        llm_response, error = await self._try_call_llm(tenant_id=tenant_id, job=job, prompt=prompt)
        if error is not None:
            return ReportGenerationOutcome(success=False, error_message=error)
        assert llm_response is not None
        report, error = self._try_parse_report(tenant_id=tenant_id, job=job, text=llm_response)
        if error is not None:
            return ReportGenerationOutcome(success=False, error_message=error)
        assert report is not None
        artifacts, error = self._try_write_report_artifacts(
            tenant_id=tenant_id,
            job_id=job_id,
            job=job,
            report=report,
        )
        if error is not None:
            return ReportGenerationOutcome(success=False, error_message=error)
        logger.info(
            "SS_STATA_REPORT_DONE",
            extra={"tenant_id": tenant_id, "job_id": job_id, "artifacts": artifacts},
        )
        return ReportGenerationOutcome(success=True, report=report, artifacts_written=artifacts)

    def _try_extract_results(
        self,
        *,
        tenant_id: str,
        job_id: str,
        table_rel_path: str,
        log_rel_path: str | None,
    ) -> tuple[MainResultSummary | None, str | None]:
        try:
            result = self._extract_results(
                tenant_id=tenant_id,
                job_id=job_id,
                table_rel_path=table_rel_path,
                log_rel_path=log_rel_path,
            )
        except (StataResultParseError, FileNotFoundError) as e:
            logger.warning(
                "SS_STATA_REPORT_PARSE_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "reason": str(e)},
            )
            return None, str(e)
        return result, None

    async def _try_call_llm(
        self,
        *,
        tenant_id: str,
        job: Job,
        prompt: str,
    ) -> tuple[str | None, str | None]:
        try:
            return (
                await self._llm.complete_text(job=job, operation="stata_report", prompt=prompt),
                None,
            )
        except (LLMCallFailedError, LLMArtifactsWriteError) as e:
            logger.warning(
                "SS_STATA_REPORT_LLM_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "error_code": e.error_code,
                    "error_message": e.message,
                },
            )
            self._try_persist_job(
                tenant_id=tenant_id,
                job=job,
                event_code="SS_STATA_REPORT_PERSIST_AFTER_LLM_FAILED",
            )
            return None, e.message

    def _try_parse_report(
        self,
        *,
        tenant_id: str,
        job: Job,
        text: str,
    ) -> tuple[StataReportResult | None, str | None]:
        try:
            return parse_stata_report(text), None
        except StataReportParseError as e:
            logger.warning(
                "SS_STATA_REPORT_RESPONSE_PARSE_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job.job_id, "reason": str(e)},
            )
            self._try_persist_job(
                tenant_id=tenant_id,
                job=job,
                event_code="SS_STATA_REPORT_PERSIST_AFTER_PARSE_FAILED",
            )
            return None, str(e)

    def _try_write_report_artifacts(
        self,
        *,
        tenant_id: str,
        job_id: str,
        job: Job,
        report: StataReportResult,
    ) -> tuple[list[str], str | None]:
        try:
            return self._write_report_artifacts(
                tenant_id=tenant_id,
                job_id=job_id,
                job=job,
                report=report,
            ), None
        except JobStoreIOError as e:
            logger.warning(
                "SS_STATA_REPORT_PERSIST_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "error_code": e.error_code,
                    "error_message": e.message,
                },
            )
            return [], e.message

    def _extract_results(
        self,
        *,
        tenant_id: str,
        job_id: str,
        table_rel_path: str,
        log_rel_path: str | None,
    ) -> MainResultSummary:
        """Extract numerical results from Stata output files."""
        table_path = self._workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=table_rel_path,
        )

        log_path: Path | None = None
        if log_rel_path is not None:
            log_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=log_rel_path,
            )

        return extract_main_result_from_artifact(table_path=table_path, log_path=log_path)

    def _build_report_input(self, *, job: Job, main_result: MainResultSummary) -> StataReportInput:
        """Build input for LLM prompt."""
        requirement = job.requirement if job.requirement is not None else ""
        draft_text = job.draft.text if job.draft else ""

        return StataReportInput(
            job_id=job.job_id,
            requirement=requirement,
            draft_text=draft_text,
            main_result=main_result,
        )

    def _try_persist_job(self, *, tenant_id: str, job: Job, event_code: str) -> None:
        try:
            self._store.save(tenant_id=tenant_id, job=job)
        except JobStoreIOError as e:
            logger.warning(
                event_code,
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job.job_id,
                    "error_code": e.error_code,
                    "error_message": e.message,
                },
            )

    def _write_report_artifacts(
        self,
        *,
        tenant_id: str,
        job_id: str,
        job: Job,
        report: StataReportResult,
    ) -> list[str]:
        """Write report artifacts and update job index."""
        timestamp = utc_now().isoformat()
        artifacts_written: list[str] = []

        # Write markdown report
        report_rel_path = f"artifacts/report_{timestamp.replace(':', '-')}.md"
        report_content = report.to_markdown()

        self._workspace.write_bytes(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=report_rel_path,
            data=report_content.encode("utf-8"),
        )
        artifacts_written.append(report_rel_path)

        # Update job artifacts index
        artifact_ref = ArtifactRef(
            kind=ArtifactKind.STATA_REPORT_INTERPRETATION,
            rel_path=report_rel_path,
        )
        job.artifacts_index.append(artifact_ref)
        self._store.save(tenant_id=tenant_id, job=job)

        return artifacts_written
