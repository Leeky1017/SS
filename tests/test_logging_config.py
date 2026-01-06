from __future__ import annotations

import json
import logging

from src.infra.logging_config import SSJsonFormatter, build_logging_config


def test_ss_json_formatter_without_extra_includes_required_keys() -> None:
    # Arrange
    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="SS_TEST_EVENT",
        args=(),
        exc_info=None,
    )
    formatter = SSJsonFormatter()

    # Act
    raw = formatter.format(record)
    payload = json.loads(raw)

    # Assert
    assert payload["event"] == "SS_TEST_EVENT"
    assert payload["job_id"] is None
    assert payload["run_id"] is None
    assert payload["step"] is None


def test_ss_json_formatter_with_extra_includes_extra_fields() -> None:
    # Arrange
    record = logging.LogRecord(
        name="test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="SS_TEST_EVENT",
        args=(),
        exc_info=None,
    )
    record.job_id = "job-1"
    record.run_id = "run-1"
    record.step = "generate"
    record.plan_id = "plan-1"
    record.outputs = 2
    formatter = SSJsonFormatter()

    # Act
    raw = formatter.format(record)
    payload = json.loads(raw)

    # Assert
    assert payload["job_id"] == "job-1"
    assert payload["run_id"] == "run-1"
    assert payload["step"] == "generate"
    assert payload["plan_id"] == "plan-1"
    assert payload["outputs"] == 2


def test_build_logging_config_with_invalid_level_defaults_to_info() -> None:
    config = build_logging_config(log_level="NOT_A_LEVEL")
    assert config["root"]["level"] == "INFO"
    assert config["handlers"]["stdout"]["level"] == "INFO"
