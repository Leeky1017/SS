from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import pytest
from openai import OpenAIError

from src.domain.llm_client import LLMProviderError
from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job
from src.infra.openai_compatible_llm_client import OpenAICompatibleLLMClient


@dataclass
class _FakeMessage:
    content: object


@dataclass
class _FakeChoice:
    message: _FakeMessage


@dataclass
class _FakeResponse:
    choices: list[_FakeChoice]


class _FakeCompletions:
    def __init__(self, *, response: _FakeResponse | Exception, calls: list[dict[str, Any]]):
        self._response = response
        self._calls = calls

    async def create(self, **kwargs: Any) -> _FakeResponse:
        self._calls.append(kwargs)
        if isinstance(self._response, Exception):
            raise self._response
        return self._response


class _FakeChat:
    def __init__(self, *, response: _FakeResponse | Exception, calls: list[dict[str, Any]]):
        self.completions = _FakeCompletions(response=response, calls=calls)


class _FakeAsyncOpenAI:
    def __init__(self, *, response: _FakeResponse | Exception, calls: list[dict[str, Any]]):
        self.chat = _FakeChat(response=response, calls=calls)


def _job() -> Job:
    return Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id="default",
        job_id="job_123",
        created_at="2026-01-01T00:00:00Z",
    )


@pytest.mark.anyio
async def test_complete_text_returns_content_and_passes_temperature_when_set() -> None:
    calls: list[dict[str, Any]] = []
    client = _FakeAsyncOpenAI(
        response=_FakeResponse(choices=[_FakeChoice(message=_FakeMessage(content="ok"))]),
        calls=calls,
    )
    llm = OpenAICompatibleLLMClient(
        client=client,
        model="m",
        temperature=0.2,
        max_tokens=123,
    )

    text = await llm.complete_text(job=_job(), operation="op", prompt="hello")

    assert text == "ok"
    assert calls and calls[0]["temperature"] == 0.2


@pytest.mark.anyio
async def test_complete_text_omits_temperature_when_none() -> None:
    calls: list[dict[str, Any]] = []
    client = _FakeAsyncOpenAI(
        response=_FakeResponse(choices=[_FakeChoice(message=_FakeMessage(content="ok"))]),
        calls=calls,
    )
    llm = OpenAICompatibleLLMClient(
        client=client,
        model="m",
        temperature=None,
        max_tokens=123,
    )

    text = await llm.complete_text(job=_job(), operation="op", prompt="hello")

    assert text == "ok"
    assert calls and "temperature" not in calls[0]


@pytest.mark.anyio
async def test_complete_text_when_openai_error_raises_llm_provider_error() -> None:
    calls: list[dict[str, Any]] = []
    client = _FakeAsyncOpenAI(response=OpenAIError("boom"), calls=calls)
    llm = OpenAICompatibleLLMClient(
        client=client,
        model="m",
        temperature=None,
        max_tokens=123,
    )

    with pytest.raises(LLMProviderError, match="boom"):
        await llm.complete_text(job=_job(), operation="op", prompt="hello")


@pytest.mark.anyio
async def test_complete_text_when_non_text_content_raises_llm_provider_error() -> None:
    calls: list[dict[str, Any]] = []
    client = _FakeAsyncOpenAI(
        response=_FakeResponse(choices=[_FakeChoice(message=_FakeMessage(content=None))]),
        calls=calls,
    )
    llm = OpenAICompatibleLLMClient(
        client=client,
        model="m",
        temperature=None,
        max_tokens=123,
    )

    with pytest.raises(LLMProviderError, match="non-text response content"):
        await llm.complete_text(job=_job(), operation="op", prompt="hello")
