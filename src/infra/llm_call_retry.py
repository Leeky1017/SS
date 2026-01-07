from __future__ import annotations

import asyncio
import logging
from dataclasses import dataclass
from typing import Callable

from src.domain.llm_client import LLMClient, LLMProviderError
from src.domain.models import Draft, Job
from src.domain.worker_retry import backoff_seconds, normalized_max_attempts


def normalized_timeout_seconds(value: float | None, *, default: float) -> float:
    try:
        seconds = float(value) if value is not None else float(default)
    except (TypeError, ValueError):
        return float(default)
    if seconds <= 0:
        return float(default)
    return float(seconds)


def normalized_backoff_seconds(value: float | None, *, default: float) -> float:
    try:
        seconds = float(value) if value is not None else float(default)
    except (TypeError, ValueError):
        return float(default)
    if seconds < 0:
        return float(default)
    return float(seconds)


@dataclass(frozen=True)
class CallOutcome:
    draft: Draft | None
    response_text: str
    error: Exception | None
    attempts: int


@dataclass(frozen=True)
class RetryPolicy:
    timeout_seconds: float
    max_attempts: int
    backoff_base_seconds: float
    backoff_max_seconds: float

    @classmethod
    def normalize(cls, policy: RetryPolicy, *, default_timeout_seconds: float) -> RetryPolicy:
        return RetryPolicy(
            timeout_seconds=normalized_timeout_seconds(
                policy.timeout_seconds, default=default_timeout_seconds
            ),
            max_attempts=normalized_max_attempts(policy.max_attempts),
            backoff_base_seconds=normalized_backoff_seconds(
                policy.backoff_base_seconds,
                default=1.0,
            ),
            backoff_max_seconds=normalized_backoff_seconds(
                policy.backoff_max_seconds,
                default=30.0,
            ),
        )


def log_call_start(
    *,
    logger: logging.Logger,
    job_id: str,
    llm_call_id: str,
    operation: str,
) -> None:
    logger.info(
        "SS_LLM_CALL_START",
        extra={"job_id": job_id, "llm_call_id": llm_call_id, "operation": operation},
    )


def log_call_done(
    *,
    logger: logging.Logger,
    job_id: str,
    llm_call_id: str,
    operation: str,
    ok: bool,
) -> None:
    logger.info(
        "SS_LLM_CALL_DONE",
        extra={
            "job_id": job_id,
            "llm_call_id": llm_call_id,
            "operation": operation,
            "ok": ok,
        },
    )


def log_timeout(
    *,
    logger: logging.Logger,
    job_id: str,
    llm_call_id: str,
    operation: str,
    attempt: int,
    timeout_seconds: float,
    will_retry: bool,
) -> None:
    logger.warning(
        "SS_LLM_CALL_TIMEOUT",
        extra={
            "job_id": job_id,
            "llm_call_id": llm_call_id,
            "operation": operation,
            "attempt": attempt,
            "timeout_seconds": timeout_seconds,
            "will_retry": will_retry,
        },
    )


def log_provider_error(
    *,
    logger: logging.Logger,
    redactor: Callable[[str], str],
    job_id: str,
    llm_call_id: str,
    operation: str,
    attempt: int,
    timeout_seconds: float,
    will_retry: bool,
    error: LLMProviderError,
) -> None:
    logger.warning(
        "SS_LLM_CALL_PROVIDER_ERROR",
        extra={
            "job_id": job_id,
            "llm_call_id": llm_call_id,
            "operation": operation,
            "attempt": attempt,
            "timeout_seconds": timeout_seconds,
            "will_retry": will_retry,
            "error_message": redactor(str(error)),
        },
    )


def log_call_failed(
    *,
    logger: logging.Logger,
    job_id: str,
    llm_call_id: str,
    operation: str,
    attempts: int,
    timeout_seconds: float,
    error: Exception | None,
) -> None:
    logger.error(
        "SS_LLM_CALL_FAILED",
        extra={
            "job_id": job_id,
            "llm_call_id": llm_call_id,
            "operation": operation,
            "attempts": attempts,
            "timeout_seconds": timeout_seconds,
            "error_type": None if error is None else type(error).__name__,
        },
    )


def retry_delay_seconds(*, attempt: int, base_seconds: float, max_seconds: float) -> float:
    return backoff_seconds(attempt=attempt, base_seconds=base_seconds, max_seconds=max_seconds)


async def _attempt_draft_preview(
    *,
    inner: LLMClient,
    job: Job,
    prompt: str,
    operation: str,
    llm_call_id: str,
    attempt: int,
    max_attempts: int,
    timeout_seconds: float,
    redactor: Callable[[str], str],
    logger: logging.Logger,
) -> tuple[Draft | None, Exception | None]:
    will_retry = attempt < max_attempts
    try:
        draft = await asyncio.wait_for(
            inner.draft_preview(job=job, prompt=prompt),
            timeout=timeout_seconds,
        )
        return draft, None
    except asyncio.TimeoutError as e:
        log_timeout(
            logger=logger,
            job_id=job.job_id,
            llm_call_id=llm_call_id,
            operation=operation,
            attempt=attempt,
            timeout_seconds=timeout_seconds,
            will_retry=will_retry,
        )
        return None, e
    except LLMProviderError as e:
        log_provider_error(
            logger=logger,
            redactor=redactor,
            job_id=job.job_id,
            llm_call_id=llm_call_id,
            operation=operation,
            attempt=attempt,
            timeout_seconds=timeout_seconds,
            will_retry=will_retry,
            error=e,
        )
        return None, e


async def call_draft_preview_with_retry(
    *,
    inner: LLMClient,
    job: Job,
    prompt: str,
    operation: str,
    llm_call_id: str,
    policy: RetryPolicy,
    redactor: Callable[[str], str],
    logger: logging.Logger,
) -> CallOutcome:
    normalized = RetryPolicy.normalize(policy, default_timeout_seconds=30.0)
    max_attempts = normalized.max_attempts
    timeout_seconds = normalized.timeout_seconds
    last_error: Exception | None = None
    for attempt in range(1, max_attempts + 1):
        draft, error = await _attempt_draft_preview(
            inner=inner,
            job=job,
            prompt=prompt,
            operation=operation,
            llm_call_id=llm_call_id,
            attempt=attempt,
            max_attempts=max_attempts,
            timeout_seconds=timeout_seconds,
            redactor=redactor,
            logger=logger,
        )
        if draft is not None:
            return CallOutcome(draft=draft, response_text=draft.text, error=None, attempts=attempt)
        last_error = error
        if attempt < max_attempts:
            await asyncio.sleep(
                retry_delay_seconds(
                    attempt=attempt,
                    base_seconds=normalized.backoff_base_seconds,
                    max_seconds=normalized.backoff_max_seconds,
                )
            )
    return CallOutcome(
        draft=None,
        response_text="",
        error=last_error,
        attempts=max_attempts,
    )
