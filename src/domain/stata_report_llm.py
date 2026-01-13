"""LLM prompt building and response parsing for Stata reports.

Core principle: LLM interprets pre-extracted numbers, never fabricates them.
"""

from __future__ import annotations

import json
import re
from json import JSONDecodeError

from src.domain.stata_report_models import (
    CoefficientRow,
    MainResultSummary,
    StataReportInput,
    StataReportParseError,
    StataReportResult,
)

_REPORT_SCHEMA = {
    "summary": "string (2-3 sentences executive summary)",
    "details": "string (detailed interpretation)",
    "limitations": "string (caveats and limitations)",
}

_JSON_BLOCK_RE = re.compile(r"```(?:json)?\s*\n?(.*?)\n?```", re.DOTALL)


def build_stata_report_prompt(input_data: StataReportInput) -> str:
    """Build prompt for LLM to interpret Stata results.

    The prompt includes pre-extracted numerical values that LLM must use verbatim.
    """
    coefficients_text = _format_coefficients(input_data.main_result.coefficients)
    metrics_text = _format_metrics(input_data.main_result)

    return "\n".join([
        "You are an econometrics expert interpreting Stata regression results.",
        "",
        "CRITICAL RULE: Do NOT modify, round, or fabricate any numbers.",
        "Use the exact numerical values provided below in your interpretation.",
        "",
        "## User's Analysis Requirement",
        input_data.requirement,
        "",
        "## Analysis Plan",
        input_data.draft_text,
        "",
        "## Model Type",
        input_data.main_result.model_type,
        "",
        "## Key Metrics (use these exact values)",
        metrics_text,
        "",
        "## Coefficient Estimates (use these exact values)",
        coefficients_text,
        "",
        "## Output Schema (return ONLY valid JSON, no markdown)",
        json.dumps(_REPORT_SCHEMA, ensure_ascii=False),
        "",
        "## Instructions",
        "1. Write a 2-3 sentence executive summary in 'summary'",
        "2. Provide detailed interpretation in 'details'",
        "3. List caveats and limitations in 'limitations'",
        "4. Reference the exact coefficient values and significance levels",
        "5. Do NOT invent statistics not provided above",
    ])


def parse_stata_report(text: str) -> StataReportResult:
    """Parse LLM response into StataReportResult.

    Raises:
        StataReportParseError: If response cannot be parsed
    """
    raw = text.strip()

    # Try to extract JSON from markdown code blocks
    if "```" in raw:
        raw = _extract_json_from_markdown(raw)

    try:
        parsed = json.loads(raw)
    except JSONDecodeError as e:
        raise StataReportParseError(f"Invalid JSON: {e}", raw_text=text) from e

    if not isinstance(parsed, dict):
        raise StataReportParseError("Response must be a JSON object", raw_text=text)

    summary = parsed.get("summary")
    details = parsed.get("details")
    limitations = parsed.get("limitations")

    if not isinstance(summary, str) or not summary.strip():
        raise StataReportParseError("Missing or empty 'summary' field", raw_text=text)
    if not isinstance(details, str) or not details.strip():
        raise StataReportParseError("Missing or empty 'details' field", raw_text=text)
    if not isinstance(limitations, str):
        limitations = "No specific limitations noted."

    return StataReportResult(
        summary=summary.strip(),
        details=details.strip(),
        limitations=limitations.strip() if limitations else "No specific limitations noted.",
    )


def _format_coefficients(coefficients: list[CoefficientRow]) -> str:
    """Format coefficient list for prompt."""
    if not coefficients:
        return "No coefficient data available."

    lines = ["| Variable | Coef | SE | p-value | Sig |"]
    lines.append("|----------|------|-----|---------|-----|")

    for coef in coefficients:
        se_str = _fmt_number(coef.std_err)
        p_str = _fmt_number(coef.p_value)
        lines.append(
            f"| {coef.var_name} | {_fmt_number(coef.coef)} | {se_str} | {p_str} | "
            f"{coef.significance} |"
        )

    return "\n".join(lines)


def _format_metrics(main_result: MainResultSummary) -> str:
    """Format model metrics for prompt."""
    lines = []

    if main_result.dep_var is not None and main_result.dep_var.strip() != "":
        lines.append(f"- Dependent variable: {main_result.dep_var}")
    if main_result.n_obs is not None:
        lines.append(f"- Number of observations: {_fmt_number(main_result.n_obs)}")
    if main_result.r_squared is not None:
        lines.append(f"- R-squared: {_fmt_number(main_result.r_squared)}")
    if main_result.r_squared_adj is not None:
        lines.append(f"- Adjusted R-squared: {_fmt_number(main_result.r_squared_adj)}")

    return "\n".join(lines) if lines else "No additional metrics available."


def _fmt_number(value: float | int | None) -> str:
    if value is None:
        return "N/A"
    return str(value)


def _extract_json_from_markdown(text: str) -> str:
    """Extract JSON from markdown code blocks."""
    match = _JSON_BLOCK_RE.search(text)
    if match is not None:
        return match.group(1).strip()
    return text
