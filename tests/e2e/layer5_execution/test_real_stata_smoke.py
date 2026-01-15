from __future__ import annotations

from pathlib import Path

import pytest

from src.config import load_config


def test_real_stata_environment_is_configured_or_skipped() -> None:
    config = load_config()
    if not config.stata_cmd:
        pytest.skip("SS_STATA_CMD not configured; skipping real-Stata smoke test")
    candidate = Path(config.stata_cmd[0])
    if not candidate.exists():
        pytest.skip(f"Stata executable not found: {candidate}")

