"""Unit tests for Stata report models."""

from __future__ import annotations

from src.domain.stata_report_models import (
    CoefficientRow,
    MainResultSummary,
    ReportGenerationOutcome,
    StataReportInput,
    StataReportParseError,
    StataReportResult,
)


class TestCoefficientRow:
    def test_basic_coefficient(self) -> None:
        row = CoefficientRow(
            var_name="treatment",
            coef=0.5,
            std_err=0.1,
            p_value=0.001,
            significance="***",
        )
        assert row.var_name == "treatment"
        assert row.coef == 0.5
        assert row.std_err == 0.1
        assert row.p_value == 0.001
        assert row.significance == "***"

    def test_minimal_coefficient(self) -> None:
        row = CoefficientRow(var_name="x", coef=1.0)
        assert row.var_name == "x"
        assert row.coef == 1.0
        assert row.std_err is None
        assert row.significance == ""


class TestMainResultSummary:
    def test_ols_result(self) -> None:
        result = MainResultSummary(
            model_type="OLS",
            dep_var="y",
            n_obs=1000,
            r_squared=0.85,
            r_squared_adj=0.84,
            coefficients=[
                CoefficientRow(var_name="x", coef=0.5, std_err=0.1, p_value=0.001),
            ],
        )
        assert result.model_type == "OLS"
        assert result.n_obs == 1000
        assert result.r_squared == 0.85
        assert len(result.coefficients) == 1

    def test_minimal_result(self) -> None:
        result = MainResultSummary(model_type="unknown")
        assert result.model_type == "unknown"
        assert result.dep_var is None
        assert result.n_obs is None
        assert result.coefficients == []


class TestStataReportInput:
    def test_full_input(self) -> None:
        main_result = MainResultSummary(model_type="OLS", n_obs=100)
        input_data = StataReportInput(
            job_id="job-123",
            requirement="Estimate effect of X on Y",
            draft_text="Run OLS regression",
            main_result=main_result,
        )
        assert input_data.job_id == "job-123"
        assert input_data.requirement == "Estimate effect of X on Y"
        assert input_data.main_result.model_type == "OLS"


class TestStataReportResult:
    def test_to_markdown(self) -> None:
        result = StataReportResult(
            summary="The treatment effect is significant.",
            details="Coefficient is 0.5 with p<0.01.",
            limitations="Sample size is limited.",
        )
        md = result.to_markdown()
        assert "## Summary" in md
        assert "The treatment effect is significant." in md
        assert "## Detailed Results" in md
        assert "## Limitations" in md

    def test_markdown_structure(self) -> None:
        result = StataReportResult(
            summary="Summary text",
            details="Details text",
            limitations="Limitations text",
        )
        md = result.to_markdown()
        lines = md.split("\n")
        assert lines[0] == "## Summary"
        assert "Summary text" in md
        assert "Details text" in md
        assert "Limitations text" in md


class TestStataReportParseError:
    def test_error_with_raw_text(self) -> None:
        error = StataReportParseError("Invalid JSON", raw_text='{"bad": json}')
        assert str(error) == "Invalid JSON"
        assert error.raw_text == '{"bad": json}'


class TestReportGenerationOutcome:
    def test_success_outcome(self) -> None:
        report = StataReportResult(
            summary="s",
            details="d",
            limitations="l",
        )
        outcome = ReportGenerationOutcome(
            success=True,
            report=report,
            artifacts_written=["report.md"],
        )
        assert outcome.success is True
        assert outcome.report is not None
        assert outcome.error_message is None

    def test_failure_outcome(self) -> None:
        outcome = ReportGenerationOutcome(
            success=False,
            error_message="Parse failed",
        )
        assert outcome.success is False
        assert outcome.report is None
        assert outcome.error_message == "Parse failed"
