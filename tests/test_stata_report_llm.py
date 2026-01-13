"""Unit tests for Stata report LLM module."""

from __future__ import annotations

import json

import pytest

from src.domain.stata_report_llm import (
    _extract_json_from_markdown,
    _format_coefficients,
    _format_metrics,
    build_stata_report_prompt,
    parse_stata_report,
)
from src.domain.stata_report_models import (
    CoefficientRow,
    MainResultSummary,
    StataReportInput,
    StataReportParseError,
)


class TestBuildStataReportPrompt:
    def test_prompt_contains_requirement(self) -> None:
        input_data = StataReportInput(
            job_id="job-1",
            requirement="Estimate treatment effect",
            draft_text="Run regression",
            main_result=MainResultSummary(model_type="OLS"),
        )
        prompt = build_stata_report_prompt(input_data)
        assert "Estimate treatment effect" in prompt
        assert "Run regression" in prompt

    def test_prompt_contains_critical_rule(self) -> None:
        input_data = StataReportInput(
            job_id="job-1",
            requirement="test",
            draft_text="test",
            main_result=MainResultSummary(model_type="OLS"),
        )
        prompt = build_stata_report_prompt(input_data)
        assert "Do NOT modify" in prompt or "do NOT modify" in prompt

    def test_prompt_contains_coefficients(self) -> None:
        input_data = StataReportInput(
            job_id="job-1",
            requirement="test",
            draft_text="test",
            main_result=MainResultSummary(
                model_type="OLS",
                coefficients=[
                    CoefficientRow(var_name="treatment", coef=0.5, std_err=0.1, p_value=0.001),
                ],
            ),
        )
        prompt = build_stata_report_prompt(input_data)
        assert "treatment" in prompt
        assert "0.5" in prompt

    def test_prompt_contains_metrics(self) -> None:
        input_data = StataReportInput(
            job_id="job-1",
            requirement="test",
            draft_text="test",
            main_result=MainResultSummary(
                model_type="OLS",
                n_obs=1000,
                r_squared=0.85,
            ),
        )
        prompt = build_stata_report_prompt(input_data)
        assert "1000" in prompt
        assert "0.85" in prompt


class TestParseStataReport:
    def test_parse_valid_json(self) -> None:
        response = json.dumps({
            "summary": "The treatment effect is significant.",
            "details": "Coefficient is 0.5 with p<0.01.",
            "limitations": "Sample size is limited.",
        })
        result = parse_stata_report(response)
        assert result.summary == "The treatment effect is significant."
        assert result.details == "Coefficient is 0.5 with p<0.01."
        assert result.limitations == "Sample size is limited."

    def test_parse_json_in_markdown(self) -> None:
        response = """```json
{
    "summary": "Summary text",
    "details": "Details text",
    "limitations": "Limitations text"
}
```"""
        result = parse_stata_report(response)
        assert result.summary == "Summary text"
        assert result.details == "Details text"

    def test_parse_missing_summary_raises(self) -> None:
        response = json.dumps({
            "details": "Details",
            "limitations": "Limitations",
        })
        with pytest.raises(StataReportParseError, match="summary"):
            parse_stata_report(response)

    def test_parse_missing_details_raises(self) -> None:
        response = json.dumps({
            "summary": "Summary",
            "limitations": "Limitations",
        })
        with pytest.raises(StataReportParseError, match="details"):
            parse_stata_report(response)

    def test_parse_missing_limitations_uses_default(self) -> None:
        response = json.dumps({
            "summary": "Summary",
            "details": "Details",
        })
        result = parse_stata_report(response)
        assert "No specific limitations" in result.limitations

    def test_parse_invalid_json_raises(self) -> None:
        with pytest.raises(StataReportParseError, match="Invalid JSON"):
            parse_stata_report("{invalid json}")

    def test_parse_non_object_raises(self) -> None:
        with pytest.raises(StataReportParseError, match="object"):
            parse_stata_report('["array", "not", "object"]')

    def test_parse_empty_summary_raises(self) -> None:
        response = json.dumps({
            "summary": "   ",
            "details": "Details",
            "limitations": "Limitations",
        })
        with pytest.raises(StataReportParseError, match="summary"):
            parse_stata_report(response)


class TestFormatCoefficients:
    def test_format_with_coefficients(self) -> None:
        coefficients = [
            CoefficientRow(
                var_name="x",
                coef=0.5,
                std_err=0.1,
                p_value=0.001,
                significance="***",
            ),
        ]
        formatted = _format_coefficients(coefficients)
        assert "x" in formatted
        assert "0.5" in formatted
        assert "***" in formatted

    def test_format_empty_list(self) -> None:
        formatted = _format_coefficients([])
        assert "No coefficient data" in formatted


class TestFormatMetrics:
    def test_format_with_metrics(self) -> None:
        result = MainResultSummary(
            model_type="OLS",
            dep_var="y",
            n_obs=1000,
            r_squared=0.85,
        )
        formatted = _format_metrics(result)
        assert "y" in formatted
        assert "1000" in formatted
        assert "0.85" in formatted

    def test_format_minimal_metrics(self) -> None:
        result = MainResultSummary(model_type="unknown")
        formatted = _format_metrics(result)
        assert "No additional metrics" in formatted


class TestExtractJsonFromMarkdown:
    def test_extract_from_code_block(self) -> None:
        text = '```json\n{"key": "value"}\n```'
        extracted = _extract_json_from_markdown(text)
        assert extracted == '{"key": "value"}'

    def test_extract_from_plain_code_block(self) -> None:
        text = '```\n{"key": "value"}\n```'
        extracted = _extract_json_from_markdown(text)
        assert extracted == '{"key": "value"}'

    def test_no_code_block_returns_original(self) -> None:
        text = '{"key": "value"}'
        extracted = _extract_json_from_markdown(text)
        assert extracted == '{"key": "value"}'
