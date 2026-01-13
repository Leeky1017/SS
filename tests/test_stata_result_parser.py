"""Unit tests for Stata result parser."""

from __future__ import annotations

from pathlib import Path

import pytest

from src.domain.stata_result_parser import (
    StataResultParseError,
    _detect_model_type,
    _determine_significance,
    _extract_metrics_from_log,
    _parse_coefficient_table,
    _safe_float,
    _safe_int,
    extract_main_result_from_artifact,
    parse_stata_output,
)


class TestDetectModelType:
    def test_detect_ols(self) -> None:
        assert _detect_model_type(table_text="regress y x", log_text="") == "OLS"
        assert _detect_model_type(table_text="", log_text="OLS regression") == "OLS"

    def test_detect_panel_fe(self) -> None:
        assert _detect_model_type(table_text="xtreg", log_text="") == "Panel_FE"
        assert _detect_model_type(table_text="", log_text="panel data fe") == "Panel_FE"

    def test_detect_did(self) -> None:
        assert _detect_model_type(table_text="DID estimate", log_text="") == "DID"
        assert _detect_model_type(table_text="", log_text="diff-in-diff") == "DID"

    def test_detect_descriptive(self) -> None:
        assert _detect_model_type(table_text="summarize", log_text="") == "descriptive"
        assert _detect_model_type(table_text="tabstat", log_text="") == "descriptive"

    def test_detect_unknown(self) -> None:
        assert _detect_model_type(table_text="", log_text="") == "unknown"


class TestExtractMetricsFromLog:
    def test_extract_ss_metrics(self) -> None:
        log = """
        SS_METRIC|name=n_obs|value=1000
        SS_METRIC|name=r2|value=0.85
        """
        metrics = _extract_metrics_from_log(log)
        assert metrics["n_obs"] == "1000"
        assert metrics["r2"] == "0.85"

    def test_extract_stata_output_metrics(self) -> None:
        log = """
        Number of obs   =      1,234
        R-squared       =     0.7500
        Adj R-squared   =     0.7400
        """
        metrics = _extract_metrics_from_log(log)
        assert metrics["n_obs"] == "1234"
        assert metrics["r2"] == "0.7500"
        assert metrics["r2_a"] == "0.7400"

    def test_empty_log(self) -> None:
        metrics = _extract_metrics_from_log("")
        assert metrics == {}


class TestParseCoefficientTable:
    def test_parse_standard_csv(self) -> None:
        csv_text = """variable,coef,se,p_value
treatment,0.5,0.1,0.001
control1,0.2,0.05,0.05
"""
        rows = _parse_coefficient_table(csv_text)
        assert len(rows) == 2
        assert rows[0].var_name == "treatment"
        assert rows[0].coef == 0.5
        assert rows[0].std_err == 0.1
        assert rows[0].p_value == 0.001

    def test_parse_alternative_column_names(self) -> None:
        csv_text = """term,estimate,stderr,pvalue
x,1.5,0.3,0.02
"""
        rows = _parse_coefficient_table(csv_text)
        assert len(rows) == 1
        assert rows[0].var_name == "x"
        assert rows[0].coef == 1.5

    def test_empty_table(self) -> None:
        rows = _parse_coefficient_table("")
        assert rows == []

    def test_header_only(self) -> None:
        csv_text = "variable,coef,se\n"
        rows = _parse_coefficient_table(csv_text)
        assert rows == []


class TestSafeConversions:
    def test_safe_float_valid(self) -> None:
        assert _safe_float("1.5") == 1.5
        assert _safe_float("-0.5") == -0.5
        assert _safe_float("1e-3") == 0.001

    def test_safe_float_invalid(self) -> None:
        assert _safe_float(None) is None
        assert _safe_float("abc") is None
        assert _safe_float("") is None

    def test_safe_int_valid(self) -> None:
        assert _safe_int("100") == 100
        assert _safe_int("1,000") == 1000
        assert _safe_int("-50") == -50

    def test_safe_int_invalid(self) -> None:
        assert _safe_int(None) is None
        assert _safe_int("abc") is None


class TestDetermineSignificance:
    def test_three_stars(self) -> None:
        assert _determine_significance(0.001) == "***"
        assert _determine_significance(0.009) == "***"

    def test_two_stars(self) -> None:
        assert _determine_significance(0.01) == "**"
        assert _determine_significance(0.04) == "**"

    def test_one_star(self) -> None:
        assert _determine_significance(0.05) == "*"
        assert _determine_significance(0.09) == "*"

    def test_no_stars(self) -> None:
        assert _determine_significance(0.10) == ""
        assert _determine_significance(0.5) == ""
        assert _determine_significance(None) == ""


class TestParseStataOutput:
    def test_full_parse(self) -> None:
        table_text = """variable,coef,se,p_value
x,0.5,0.1,0.001
"""
        log_text = """
        regress y x
        SS_METRIC|name=n_obs|value=500
        """
        result = parse_stata_output(table_text=table_text, log_text=log_text)
        assert result.model_type == "OLS"
        assert result.n_obs == 500
        assert len(result.coefficients) == 1
        assert result.coefficients[0].var_name == "x"


class TestExtractMainResultFromArtifact:
    def test_extract_from_file(self, tmp_path: Path) -> None:
        table_file = tmp_path / "table.csv"
        table_file.write_text("variable,coef,se\nx,1.0,0.1\n")

        log_file = tmp_path / "result.log"
        log_file.write_text("regress y x\nSS_METRIC|name=n_obs|value=100\n")

        result = extract_main_result_from_artifact(
            table_path=table_file,
            log_path=log_file,
        )
        assert result.model_type == "OLS"
        assert result.n_obs == 100
        assert len(result.coefficients) == 1

    def test_missing_table_file(self, tmp_path: Path) -> None:
        missing_path = tmp_path / "missing.csv"
        with pytest.raises(StataResultParseError, match="not found"):
            extract_main_result_from_artifact(table_path=missing_path)

    def test_table_only(self, tmp_path: Path) -> None:
        table_file = tmp_path / "table.csv"
        table_file.write_text("variable,coef\ny,2.0\n")

        result = extract_main_result_from_artifact(table_path=table_file)
        assert len(result.coefficients) == 1
        assert result.coefficients[0].coef == 2.0
