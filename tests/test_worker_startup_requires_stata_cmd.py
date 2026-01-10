from __future__ import annotations

from pathlib import Path

import pytest

from src.config import load_config
from src.infra.exceptions import SSError
from src.infra.prometheus_metrics import PrometheusMetrics
from src.worker import _build_worker_service


def test_worker_startup_without_ss_stata_cmd_raises_stable_error_code(tmp_path: Path) -> None:
    config = load_config(
        env={
            "SS_LLM_PROVIDER": "yunwu",
            "SS_LLM_API_KEY": "test-key",
            "SS_JOBS_DIR": str(tmp_path / "jobs"),
            "SS_QUEUE_DIR": str(tmp_path / "queue"),
            "SS_WORKER_METRICS_PORT": "0",
        }
    )

    with pytest.raises(SSError) as exc:
        _build_worker_service(config=config, metrics=PrometheusMetrics())

    assert exc.value.error_code == "STATA_CMD_NOT_CONFIGURED"
