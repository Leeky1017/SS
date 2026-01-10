from __future__ import annotations

from openai import AsyncOpenAI

from src.config import Config
from src.domain.llm_client import LLMClient
from src.infra.exceptions import LLMConfigurationError
from src.infra.llm_tracing import TracedLLMClient
from src.infra.openai_compatible_llm_client import OpenAICompatibleLLMClient


def build_llm_client(*, config: Config) -> LLMClient:
    provider = config.llm_provider
    if provider in {"", "stub"}:
        raise LLMConfigurationError(message="SS_LLM_PROVIDER is required and must not be 'stub'")
    if provider in {"openai", "openai_compatible", "yunwu"}:
        return _build_openai_compatible(config=config)
    raise LLMConfigurationError(message=f"unsupported SS_LLM_PROVIDER: {provider}")


def _build_openai_compatible(*, config: Config) -> LLMClient:
    if config.llm_api_key == "":
        raise LLMConfigurationError(message="SS_LLM_API_KEY is required for SS_LLM_PROVIDER")
    if config.llm_model == "":
        raise LLMConfigurationError(message="SS_LLM_MODEL must not be empty for SS_LLM_PROVIDER")
    if config.llm_base_url == "":
        raise LLMConfigurationError(message="SS_LLM_BASE_URL must not be empty for SS_LLM_PROVIDER")

    inner = OpenAICompatibleLLMClient(
        client=AsyncOpenAI(api_key=config.llm_api_key, base_url=config.llm_base_url),
        model=config.llm_model,
        temperature=config.llm_temperature,
        max_tokens=1024,
    )
    return TracedLLMClient(
        inner=inner,
        jobs_dir=config.jobs_dir,
        model=config.llm_model,
        temperature=config.llm_temperature,
        seed=config.llm_seed,
        timeout_seconds=config.llm_timeout_seconds,
        max_attempts=config.llm_max_attempts,
        retry_backoff_base_seconds=config.llm_retry_backoff_base_seconds,
        retry_backoff_max_seconds=config.llm_retry_backoff_max_seconds,
    )
