from __future__ import annotations

from src.domain.do_template_plan_support import template_params_for


def test_template_params_for_with_t07_returns_numeric_vars_param() -> None:
    params = template_params_for(template_id="T07", analysis_vars=["y", "treat", "x1"])

    assert params["__NUMERIC_VARS__"] == "y treat x1"
