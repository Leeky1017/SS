from __future__ import annotations

from typing import Any

from openai import AsyncOpenAI, OpenAIError

from src.domain.llm_client import LLMClient, LLMProviderError
from src.domain.models import Job


class OpenAICompatibleLLMClient(LLMClient):
    def __init__(
        self,
        *,
        client: AsyncOpenAI,
        model: str,
        temperature: float | None,
        max_tokens: int,
    ) -> None:
        self._client = client
        self._model = model
        self._temperature = temperature
        self._max_tokens = max_tokens

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        try:
            kwargs: dict[str, Any] = {}
            if self._temperature is not None:
                kwargs["temperature"] = self._temperature
            response = await self._client.chat.completions.create(
                model=self._model,
                messages=[{"role": "user", "content": prompt}],
                max_tokens=self._max_tokens,
                **kwargs,
            )
        except OpenAIError as e:
            raise LLMProviderError(str(e)) from e
        content = response.choices[0].message.content
        if content is None:
            raise LLMProviderError("empty response content")
        return content
