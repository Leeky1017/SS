from __future__ import annotations

import os
from pathlib import Path

from src.config import load_config


def test_load_config_when_dotenv_present_loads_required_values(tmp_path: Path, monkeypatch) -> None:
    original_provider = os.environ.pop("SS_LLM_PROVIDER", None)
    original_api_key = os.environ.pop("SS_LLM_API_KEY", None)
    try:
        monkeypatch.chdir(tmp_path)
        (tmp_path / ".env").write_text(
            "SS_LLM_PROVIDER=yunwu\nSS_LLM_API_KEY=test-key\n",
            encoding="utf-8",
        )

        config = load_config()

        assert config.llm_provider == "yunwu"
        assert config.llm_api_key == "test-key"
    finally:
        if original_provider is None:
            os.environ.pop("SS_LLM_PROVIDER", None)
        else:
            os.environ["SS_LLM_PROVIDER"] = original_provider
        if original_api_key is None:
            os.environ.pop("SS_LLM_API_KEY", None)
        else:
            os.environ["SS_LLM_API_KEY"] = original_api_key
