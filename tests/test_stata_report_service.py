"""Integration tests for Stata report service."""

from __future__ import annotations

import asyncio
import json

import pytest

from src.domain.llm_client import LLMClient
from src.domain.models import Draft, Job
from src.domain.stata_report_service import StataReportService
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.utils.job_workspace import resolve_job_dir
from src.utils.time import utc_now


class FakeReportLLMClient(LLMClient):
    """Fake LLM client that returns valid report JSON."""

    def __init__(self, response: str | None = None):
        if response is None:
            response = json.dumps(
                {
                    "summary": "The treatment effect is statistically significant at p<0.01.",
                    "details": "The coefficient of 0.5 indicates a positive relationship.",
                    "limitations": "Results may be sensitive to model specification.",
                }
            )
        self._response = response

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        return Draft(text=self._response, created_at=utc_now().isoformat())

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        return self._response


class FailingLLMClient(LLMClient):
    """LLM client that raises an error."""

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        from src.infra.exceptions import LLMCallFailedError
        raise LLMCallFailedError(job_id=job.job_id, llm_call_id="test-call")

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        from src.infra.exceptions import LLMCallFailedError
        raise LLMCallFailedError(job_id=job.job_id, llm_call_id="test-call")


@pytest.fixture
def setup_job_with_table(job_service, jobs_dir, store):
    """Create a job with a table artifact."""
    job = job_service.create_job(requirement="Estimate effect of X on Y")
    job_dir = resolve_job_dir(jobs_dir=jobs_dir, tenant_id="default", job_id=job.job_id)

    # Create artifacts directory and table file
    artifacts_dir = job_dir / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    table_path = artifacts_dir / "table_result.csv"
    table_path.write_text(
        "variable,coef,se,p_value\n"
        "treatment,0.5,0.1,0.001\n"
        "control1,0.2,0.05,0.05\n"
    )

    log_path = artifacts_dir / "result.log"
    log_path.write_text(
        "regress y treatment control1\n"
        "SS_METRIC|name=n_obs|value=1000\n"
        "SS_METRIC|name=r2|value=0.85\n"
    )

    return job, "artifacts/table_result.csv", "artifacts/result.log"


def test_generate_report_success(
    job_service,
    store,
    jobs_dir,
    setup_job_with_table,
) -> None:
    """Test successful report generation."""
    job, table_rel_path, log_rel_path = setup_job_with_table

    service = StataReportService(
        store=store,
        llm=FakeReportLLMClient(),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path=table_rel_path,
            log_rel_path=log_rel_path,
        )
    )

    assert outcome.success is True
    assert outcome.report is not None
    assert "treatment effect" in outcome.report.summary
    assert len(outcome.artifacts_written) == 1
    assert outcome.artifacts_written[0].endswith(".md")

    # Verify artifact was written
    updated_job = store.load(job.job_id)
    report_artifacts = [
        ref for ref in updated_job.artifacts_index
        if ref.kind.value == "stata.report.interpretation"
    ]
    assert len(report_artifacts) == 1


def test_generate_report_without_log(
    job_service,
    store,
    jobs_dir,
    setup_job_with_table,
) -> None:
    """Test report generation without log file."""
    job, table_rel_path, _ = setup_job_with_table

    service = StataReportService(
        store=store,
        llm=FakeReportLLMClient(),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path=table_rel_path,
        )
    )

    assert outcome.success is True
    assert outcome.report is not None


def test_generate_report_missing_table(
    job_service,
    store,
    jobs_dir,
) -> None:
    """Test report generation with missing table file."""
    job = job_service.create_job(requirement="test")

    service = StataReportService(
        store=store,
        llm=FakeReportLLMClient(),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path="artifacts/missing.csv",
        )
    )

    assert outcome.success is False
    assert outcome.error_message is not None


def test_generate_report_llm_failure(
    job_service,
    store,
    jobs_dir,
    setup_job_with_table,
) -> None:
    """Test report generation when LLM fails."""
    job, table_rel_path, log_rel_path = setup_job_with_table

    service = StataReportService(
        store=store,
        llm=FailingLLMClient(),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path=table_rel_path,
            log_rel_path=log_rel_path,
        )
    )

    assert outcome.success is False
    assert "llm call failed" in str(outcome.error_message)


def test_generate_report_invalid_llm_response(
    job_service,
    store,
    jobs_dir,
    setup_job_with_table,
) -> None:
    """Test report generation with invalid LLM response."""
    job, table_rel_path, log_rel_path = setup_job_with_table

    service = StataReportService(
        store=store,
        llm=FakeReportLLMClient(response="not valid json"),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path=table_rel_path,
            log_rel_path=log_rel_path,
        )
    )

    assert outcome.success is False
    assert "Invalid JSON" in str(outcome.error_message)


def test_report_markdown_content(
    job_service,
    store,
    jobs_dir,
    setup_job_with_table,
) -> None:
    """Test that generated markdown report has correct structure."""
    job, table_rel_path, log_rel_path = setup_job_with_table

    service = StataReportService(
        store=store,
        llm=FakeReportLLMClient(),
        workspace=FileJobWorkspaceStore(jobs_dir=jobs_dir),
    )

    outcome = asyncio.run(
        service.generate_report(
            job_id=job.job_id,
            table_rel_path=table_rel_path,
            log_rel_path=log_rel_path,
        )
    )

    assert outcome.success is True
    assert outcome.report is not None

    markdown = outcome.report.to_markdown()
    assert "## Summary" in markdown
    assert "## Detailed Results" in markdown
    assert "## Limitations" in markdown
