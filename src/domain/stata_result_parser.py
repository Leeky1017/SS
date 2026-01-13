"""Rule-based parser for Stata export tables.

Extracts numerical values from Stata output. LLM never touches these numbers.
"""

from __future__ import annotations

import csv
import re
from io import StringIO
from pathlib import Path

from src.domain.stata_report_models import CoefficientRow, MainResultSummary


class StataResultParseError(Exception):
    """Raised when Stata result cannot be parsed."""


def extract_main_result_from_artifact(
    *,
    table_path: Path,
    log_path: Path | None = None,
) -> MainResultSummary:
    """Extract main result from Stata export table and optional log.

    Args:
        table_path: Path to exported CSV table
        log_path: Optional path to Stata log for additional metrics

    Returns:
        MainResultSummary with extracted numerical values
    """
    if not table_path.exists():
        raise StataResultParseError(f"Table file not found: {table_path}")

    table_text = table_path.read_text(encoding="utf-8", errors="replace")
    log_text = ""
    if log_path is not None and log_path.exists():
        log_text = log_path.read_text(encoding="utf-8", errors="replace")

    return parse_stata_output(table_text=table_text, log_text=log_text)


def parse_stata_output(*, table_text: str, log_text: str = "") -> MainResultSummary:
    """Parse Stata output from table CSV and log text."""
    model_type = _detect_model_type(table_text=table_text, log_text=log_text)
    metrics = _extract_metrics_from_log(log_text)
    coefficients = _parse_coefficient_table(table_text)

    return MainResultSummary(
        model_type=model_type,
        dep_var=metrics.get("dep_var"),
        n_obs=_safe_int(metrics.get("n_obs")),
        r_squared=_safe_float(metrics.get("r2")),
        r_squared_adj=_safe_float(metrics.get("r2_a")),
        coefficients=coefficients,
    )


def _detect_model_type(*, table_text: str, log_text: str) -> str:
    """Detect regression model type from output."""
    combined = (table_text + " " + log_text).lower()

    if "did" in combined or "diff-in-diff" in combined or "difference-in-difference" in combined:
        return "DID"
    if "xtreg" in combined or "panel" in combined or "fe" in combined:
        return "Panel_FE"
    if "regress" in combined or "ols" in combined:
        return "OLS"
    if "summ" in combined or "tabstat" in combined or "descriptive" in combined:
        return "descriptive"
    return "unknown"


def _extract_metrics_from_log(log_text: str) -> dict[str, str]:
    """Extract SS_METRIC values from Stata log."""
    metrics: dict[str, str] = {}
    pattern = re.compile(r"SS_METRIC\|name=(\w+)\|value=([^\s|]+)")

    for match in pattern.finditer(log_text):
        name, value = match.groups()
        metrics[name] = value

    # Also try to extract from regression output
    n_obs_match = re.search(r"Number of obs\s*=\s*([\d,]+)", log_text)
    if n_obs_match and "n_obs" not in metrics:
        metrics["n_obs"] = n_obs_match.group(1).replace(",", "")

    r2_match = re.search(r"R-squared\s*=\s*([\d.]+)", log_text)
    if r2_match and "r2" not in metrics:
        metrics["r2"] = r2_match.group(1)

    r2_adj_match = re.search(r"Adj R-squared\s*=\s*([\d.]+)", log_text)
    if r2_adj_match and "r2_a" not in metrics:
        metrics["r2_a"] = r2_adj_match.group(1)

    return metrics


def _parse_coefficient_table(table_text: str) -> list[CoefficientRow]:
    """Parse coefficient rows from CSV table."""
    if not table_text.strip():
        return []

    rows: list[CoefficientRow] = []
    try:
        reader = csv.DictReader(StringIO(table_text))
        for row in reader:
            coef_row = _parse_single_coefficient_row(row)
            if coef_row is not None:
                rows.append(coef_row)
    except csv.Error:
        # Try alternative parsing for non-standard formats
        rows = _parse_coefficient_table_fallback(table_text)

    return rows


def _parse_single_coefficient_row(row: dict[str, str]) -> CoefficientRow | None:
    """Parse a single coefficient row from CSV dict."""
    # Try common column name patterns
    var_name = _get_first_match(row, ["variable", "var", "varname", "name", "term"])
    coef_str = _get_first_match(row, ["coef", "coefficient", "b", "estimate", "beta"])

    if var_name is None or coef_str is None:
        return None

    coef = _safe_float(coef_str)
    if coef is None:
        return None

    std_err = _safe_float(_get_first_match(row, ["se", "std_err", "stderr", "std.err"]))
    t_stat = _safe_float(_get_first_match(row, ["t", "t_stat", "tstat", "z"]))
    p_value = _safe_float(_get_first_match(row, ["p", "pvalue", "p_value", "p>|t|", "p>|z|"]))
    ci_lower = _safe_float(_get_first_match(row, ["ci_lower", "ll", "ci_l", "[95%_conf"]))
    ci_upper = _safe_float(_get_first_match(row, ["ci_upper", "ul", "ci_u", "interval]"]))

    significance = _determine_significance(p_value)

    return CoefficientRow(
        var_name=var_name.strip(),
        coef=coef,
        std_err=std_err,
        t_stat=t_stat,
        p_value=p_value,
        ci_lower=ci_lower,
        ci_upper=ci_upper,
        significance=significance,
    )


def _parse_coefficient_table_fallback(table_text: str) -> list[CoefficientRow]:
    """Fallback parser for non-standard table formats."""
    rows: list[CoefficientRow] = []
    lines = table_text.strip().split("\n")

    for line in lines[1:]:  # Skip header
        parts = re.split(r"[,\t]+", line.strip())
        if len(parts) >= 2:
            var_name = parts[0].strip()
            coef = _safe_float(parts[1])
            if var_name and coef is not None:
                std_err = _safe_float(parts[2]) if len(parts) > 2 else None
                p_value = _safe_float(parts[3]) if len(parts) > 3 else None
                rows.append(
                    CoefficientRow(
                        var_name=var_name,
                        coef=coef,
                        std_err=std_err,
                        p_value=p_value,
                        significance=_determine_significance(p_value),
                    )
                )

    return rows


def _get_first_match(row: dict[str, str], keys: list[str]) -> str | None:
    """Get first matching value from row by trying multiple keys."""
    row_lower = {k.lower().strip(): v for k, v in row.items()}
    for key in keys:
        if key.lower() in row_lower:
            return row_lower[key.lower()]
    return None


def _safe_float(value: str | None) -> float | None:
    """Safely convert string to float."""
    if value is None:
        return None
    try:
        cleaned = re.sub(r"[^\d.\-eE]", "", str(value))
        return float(cleaned) if cleaned else None
    except (ValueError, TypeError):
        return None


def _safe_int(value: str | None) -> int | None:
    """Safely convert string to int."""
    if value is None:
        return None
    try:
        cleaned = re.sub(r"[^\d\-]", "", str(value))
        return int(cleaned) if cleaned else None
    except (ValueError, TypeError):
        return None


def _determine_significance(p_value: float | None) -> str:
    """Determine significance stars from p-value."""
    if p_value is None:
        return ""
    if p_value < 0.01:
        return "***"
    if p_value < 0.05:
        return "**"
    if p_value < 0.10:
        return "*"
    return ""
