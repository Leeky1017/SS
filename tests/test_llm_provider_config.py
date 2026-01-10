from __future__ import annotations

import pytest

from src.config import load_config
from src.infra.exceptions import LLMConfigurationError


def test_load_config_with_stub_llm_provider_raises_llm_configuration_error() -> None:
    with pytest.raises(LLMConfigurationError) as exc:
        load_config(env={"SS_LLM_PROVIDER": "stub", "SS_LLM_API_KEY": "test-key"})
    assert exc.value.error_code == "LLM_CONFIG_INVALID"


def test_load_config_with_missing_llm_provider_raises_llm_configuration_error() -> None:
    with pytest.raises(LLMConfigurationError) as exc:
        load_config(env={"SS_LLM_API_KEY": "test-key"})
    assert exc.value.error_code == "LLM_CONFIG_INVALID"
