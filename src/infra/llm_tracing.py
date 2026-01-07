from __future__ import annotations

import json
import logging
import os
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import cast

from opentelemetry.trace import get_tracer

from src.domain.llm_client import LLMClient
from src.domain.models import ArtifactKind, ArtifactRef, Draft, Job, is_safe_job_rel_path
from src.domain.worker_retry import normalized_max_attempts
from src.infra.exceptions import LLMArtifactsWriteError, LLMCallFailedError
from src.infra.llm_call_retry import (
    RetryPolicy,
    call_complete_text_with_retry,
    log_call_done,
    log_call_failed,
    log_call_start,
    normalized_backoff_seconds,
    normalized_timeout_seconds,
)
from src.infra.llm_tracing_support import (
    LLM_META_SCHEMA_VERSION_V1,
    estimate_tokens,
    llm_call_id,
    redact_text,
    sha256_hex,
)
from src.utils.job_workspace import resolve_job_dir
from src.utils.json_types import JsonObject
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

@dataclass(frozen=True)
class LLMCallArtifacts:
    prompt_ref: ArtifactRef
    response_ref: ArtifactRef
    meta_ref: ArtifactRef

class TracedLLMClient(LLMClient):
    def __init__(
        self,
        *,
        inner: LLMClient,
        jobs_dir: Path,
        model: str,
        temperature: float | None = None,
        seed: str | int | None = None,
        timeout_seconds: float = 30.0,
        max_attempts: int = 3,
        retry_backoff_base_seconds: float = 1.0,
        retry_backoff_max_seconds: float = 30.0,
    ):
        self._inner = inner
        self._jobs_dir = Path(jobs_dir)
        self._model = model
        self._temperature = temperature
        self._seed = seed
        self._timeout_seconds = normalized_timeout_seconds(timeout_seconds, default=30.0)
        self._max_attempts = normalized_max_attempts(max_attempts)
        self._retry_backoff_base_seconds = normalized_backoff_seconds(
            retry_backoff_base_seconds,
            default=1.0,
        )
        self._retry_backoff_max_seconds = normalized_backoff_seconds(
            retry_backoff_max_seconds,
            default=30.0,
        )

    async def complete_text(self, *, job: Job, operation: str, prompt: str) -> str:
        return await self._call_and_record(job=job, operation=operation, prompt=prompt)

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        text = await self.complete_text(job=job, operation="draft_preview", prompt=prompt)
        return Draft(text=text, created_at=utc_now().isoformat())

    async def _call_and_record(self, *, job: Job, operation: str, prompt: str) -> str:
        started_at = utc_now()
        call_id = llm_call_id(
            operation=operation,
            started_at=started_at,
            prompt_fingerprint=sha256_hex(prompt),
        )
        log_call_start(logger=logger, job_id=job.job_id, llm_call_id=call_id, operation=operation)

        started_perf = time.perf_counter()
        tracer = get_tracer(__name__)
        with tracer.start_as_current_span(f"ss.llm.{operation}") as span:
            span.set_attribute("ss.job_id", job.job_id)
            span.set_attribute("ss.llm_call_id", call_id)
            span.set_attribute("ss.model", self._model)
            outcome = await call_complete_text_with_retry(
                inner=self._inner,
                job=job,
                prompt=prompt,
                operation=operation,
                llm_call_id=call_id,
                policy=RetryPolicy(
                    timeout_seconds=self._timeout_seconds,
                    max_attempts=self._max_attempts,
                    backoff_base_seconds=self._retry_backoff_base_seconds,
                    backoff_max_seconds=self._retry_backoff_max_seconds,
                ),
                redactor=redact_text,
                logger=logger,
            )
            span.set_attribute("ss.ok", outcome.text is not None)
        ended_at = utc_now()
        duration_ms = int((time.perf_counter() - started_perf) * 1000)

        meta = self._build_meta(
            call_id=call_id,
            operation=operation,
            started_at=started_at.isoformat(),
            ended_at=ended_at.isoformat(),
            duration_ms=duration_ms,
            prompt=prompt,
            response=outcome.response_text,
            error=outcome.error,
            attempts=outcome.attempts,
        )
        artifacts = self._write_artifacts(
            tenant_id=job.tenant_id,
            job_id=job.job_id,
            call_id=call_id,
            prompt=prompt,
            response=outcome.response_text,
            meta=meta,
        )
        refs = [artifacts.prompt_ref, artifacts.response_ref, artifacts.meta_ref]
        job.artifacts_index.extend(refs)

        log_call_done(
            logger=logger,
            job_id=job.job_id,
            llm_call_id=call_id,
            operation=operation,
            ok=bool(meta["ok"]),
        )
        if outcome.text is None:
            log_call_failed(
                logger=logger,
                job_id=job.job_id,
                llm_call_id=call_id,
                operation=operation,
                attempts=outcome.attempts,
                timeout_seconds=self._timeout_seconds,
                error=outcome.error,
            )
            raise LLMCallFailedError(job_id=job.job_id, llm_call_id=call_id) from outcome.error
        return outcome.response_text

    def _build_meta(
        self,
        *,
        call_id: str,
        operation: str,
        started_at: str,
        ended_at: str,
        duration_ms: int,
        prompt: str,
        response: str,
        error: Exception | None,
        attempts: int,
    ) -> JsonObject:
        error_message = None
        if error is not None:
            error_message = redact_text(str(error))
        seed = self._seed
        if isinstance(seed, str):
            seed = redact_text(seed)
        return cast(
            JsonObject,
            {
                "schema_version": LLM_META_SCHEMA_VERSION_V1,
                "llm_call_id": call_id,
                "operation": operation,
                "started_at": started_at,
                "ended_at": ended_at,
                "duration_ms": duration_ms,
                "ok": error is None,
                "model": self._model,
                "temperature": self._temperature,
                "seed": seed,
                "prompt_fingerprint": sha256_hex(prompt),
                "response_fingerprint": sha256_hex(response),
                "prompt_token_estimate": estimate_tokens(prompt),
                "response_token_estimate": estimate_tokens(response),
                "error_type": None if error is None else type(error).__name__,
                "error_message": error_message,
                "timeout_seconds": self._timeout_seconds,
                "max_attempts": self._max_attempts,
                "attempts": attempts,
            },
        )

    def _write_artifacts(
        self,
        *,
        tenant_id: str,
        job_id: str,
        call_id: str,
        prompt: str,
        response: str,
        meta: JsonObject,
    ) -> LLMCallArtifacts:
        rel_dir = PurePosixPath("artifacts") / "llm" / call_id
        prompt_rel = (rel_dir / "prompt.txt").as_posix()
        response_rel = (rel_dir / "response.txt").as_posix()
        meta_rel = (rel_dir / "meta.json").as_posix()
        written: list[Path] = []
        try:
            prompt_path = self._safe_artifact_path(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=prompt_rel,
            )
            response_path = self._safe_artifact_path(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=response_rel,
            )
            meta_path = self._safe_artifact_path(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=meta_rel,
            )

            self._atomic_write_text(path=prompt_path, text=redact_text(prompt))
            written.append(prompt_path)
            self._atomic_write_text(path=response_path, text=redact_text(response))
            written.append(response_path)
            self._atomic_write_json(path=meta_path, payload=meta)
            written.append(meta_path)
        except (OSError, ValueError) as e:
            for path in written:
                try:
                    path.unlink(missing_ok=True)
                except OSError:
                    logger.warning(
                        "SS_LLM_ARTIFACTS_CLEANUP_FAILED",
                        extra={"job_id": job_id, "llm_call_id": call_id, "path": str(path)},
                    )
            logger.warning(
                "SS_LLM_ARTIFACTS_WRITE_FAILED",
                extra={"job_id": job_id, "llm_call_id": call_id, "reason": str(e)},
            )
            raise LLMArtifactsWriteError(job_id=job_id, llm_call_id=call_id) from e
        return LLMCallArtifacts(
            prompt_ref=ArtifactRef(kind=ArtifactKind.LLM_PROMPT, rel_path=prompt_rel),
            response_ref=ArtifactRef(kind=ArtifactKind.LLM_RESPONSE, rel_path=response_rel),
            meta_ref=ArtifactRef(kind=ArtifactKind.LLM_META, rel_path=meta_rel),
        )

    def _atomic_write_text(self, *, path: Path, text: str) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp: Path | None = None
        try:
            with tempfile.NamedTemporaryFile(
                "w",
                encoding="utf-8",
                dir=str(path.parent),
                delete=False,
            ) as f:
                tmp = Path(f.name)
                f.write(text)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, path)
        except OSError:
            if tmp is not None:
                try:
                    tmp.unlink(missing_ok=True)
                except OSError:
                    logger.warning("SS_ATOMIC_WRITE_TMP_CLEANUP_FAILED", extra={"tmp": str(tmp)})
            raise

    def _atomic_write_json(self, *, path: Path, payload: JsonObject) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
        self._atomic_write_text(path=path, text=data)

    def _safe_artifact_path(self, *, tenant_id: str, job_id: str, rel_path: str) -> Path:
        if not is_safe_job_rel_path(rel_path):
            raise ValueError("unsafe_rel_path")
        job_dir = resolve_job_dir(jobs_dir=self._jobs_dir, tenant_id=tenant_id, job_id=job_id)
        if job_dir is None:
            raise ValueError("unsafe_job_id")
        base = job_dir.resolve(strict=False)
        resolved = (job_dir / rel_path).resolve(strict=False)
        if not resolved.is_relative_to(base):
            raise ValueError("symlink_escape")
        return resolved
