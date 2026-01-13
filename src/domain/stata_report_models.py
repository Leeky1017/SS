"""Models for Stata result interpretation reports.

Core principle: LLM interprets, never fabricates numbers.
All numerical values must be extracted by rule-based code.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CoefficientRow(BaseModel):
    """Single coefficient row from regression output."""

    model_config = ConfigDict(extra="forbid")

    var_name: str
    coef: float
    std_err: float | None = None
    t_stat: float | None = None
    p_value: float | None = None
    ci_lower: float | None = None
    ci_upper: float | None = None
    significance: Literal["***", "**", "*", ""] = ""


class MainResultSummary(BaseModel):
    """Extracted numerical values from Stata regression output.

    All values are extracted by rule-based parser, never by LLM.
    """

    model_config = ConfigDict(extra="forbid")

    model_type: str = Field(description="OLS, Panel_FE, DID, descriptive, etc.")
    dep_var: str | None = Field(default=None, description="Dependent variable name")
    n_obs: int | None = Field(default=None, description="Number of observations")
    r_squared: float | None = Field(default=None, description="R-squared")
    r_squared_adj: float | None = Field(default=None, description="Adjusted R-squared")
    coefficients: list[CoefficientRow] = Field(default_factory=list)


class StataReportInput(BaseModel):
    """Input for LLM report generation."""

    model_config = ConfigDict(extra="forbid")

    job_id: str
    requirement: str = Field(description="User's original analysis requirement")
    draft_text: str = Field(description="Draft analysis plan text")
    main_result: MainResultSummary


class StataReportResult(BaseModel):
    """LLM-generated interpretation report."""

    model_config = ConfigDict(extra="forbid")

    summary: str = Field(description="Executive summary (2-3 sentences)")
    details: str = Field(description="Detailed interpretation of results")
    limitations: str = Field(description="Caveats and limitations")

    def to_markdown(self) -> str:
        """Render report as markdown."""
        sections = [
            "## Summary",
            "",
            self.summary,
            "",
            "## Detailed Results",
            "",
            self.details,
            "",
            "## Limitations",
            "",
            self.limitations,
        ]
        return "\n".join(sections)


class StataReportParseError(Exception):
    """Raised when LLM response cannot be parsed into StataReportResult."""

    def __init__(self, message: str, raw_text: str):
        super().__init__(message)
        self.raw_text = raw_text


@dataclass(frozen=True)
class ReportGenerationOutcome:
    """Result of report generation attempt."""

    success: bool
    report: StataReportResult | None = None
    error_message: str | None = None
    artifacts_written: list[str] = field(default_factory=list)
