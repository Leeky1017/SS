from __future__ import annotations

import hashlib
import json
import logging
import re
import time
from dataclasses import dataclass
from pathlib import Path, PurePosixPath

from src.domain.llm_client import LLMClient, LLMProviderError
from src.domain.models import ArtifactKind, ArtifactRef, Draft, Job, is_safe_job_rel_path
from src.infra.exceptions import LLMArtifactsWriteError, LLMCallFailedError
from src.utils.time import utc_now

logger = logging.getLogger(__name__)

LLM_META_SCHEMA_VERSION_V1 = 1

_REDACTIONS: list[tuple[re.Pattern[str], str]] = [
    (re.compile(r"(?i)(authorization\\s*:\\s*bearer)\\s+[^\\s]+"), r"\\1 <REDACTED>"),
    (re.compile(r"sk-[A-Za-z0-9]{20,}"), "sk-<REDACTED>"),
    (
        re.compile(r"(?i)\\b(api[_-]?key|token|secret|password)\\b\\s*[:=]\\s*[^\\s,;]+"),
        r"\\1=<REDACTED>",
    ),
    (re.compile(r"/home/[^\\s]+"), "/home/<REDACTED>"),
    (re.compile(r"/Users/[^\\s]+"), "/Users/<REDACTED>"),
]


def redact_text(text: str) -> str:
    value = text
    for pattern, replacement in _REDACTIONS:
        value = pattern.sub(replacement, value)
    return value


def _sha256_hex(value: str) -> str:
    return hashlib.sha256(value.encode("utf-8", errors="ignore")).hexdigest()


def _estimate_tokens(text: str) -> int:
    stripped = text.strip()
    if stripped == "":
        return 0
    return max(1, len(stripped) // 4)


def _llm_call_id(*, operation: str, started_at, prompt_fingerprint: str) -> str:
    ts = started_at.strftime("%Y%m%dT%H%M%S") + f"{started_at.microsecond:06d}Z"
    return f"{operation}-{ts}-{prompt_fingerprint[:12]}"


@dataclass(frozen=True)
class LLMCallArtifacts:
    prompt_ref: ArtifactRef
    response_ref: ArtifactRef
    meta_ref: ArtifactRef

    def as_list(self) -> list[ArtifactRef]:
        return [self.prompt_ref, self.response_ref, self.meta_ref]


class TracedLLMClient(LLMClient):
    def __init__(
        self,
        *,
        inner: LLMClient,
        jobs_dir: Path,
        model: str,
        temperature: float | None = None,
        seed: str | int | None = None,
    ):
        self._inner = inner
        self._jobs_dir = Path(jobs_dir)
        self._model = model
        self._temperature = temperature
        self._seed = seed

    async def draft_preview(self, *, job: Job, prompt: str) -> Draft:
        return await self._call_and_record(job=job, operation="draft_preview", prompt=prompt)

    async def _call_and_record(self, *, job: Job, operation: str, prompt: str) -> Draft:
        started_at = utc_now()
        call_id = _llm_call_id(
            operation=operation,
            started_at=started_at,
            prompt_fingerprint=_sha256_hex(prompt),
        )
        logger.info(
            "SS_LLM_CALL_START",
            extra={"job_id": job.job_id, "llm_call_id": call_id, "operation": operation},
        )

        error: Exception | None = None
        response_text = ""
        started_perf = time.perf_counter()
        try:
            draft = await self._inner.draft_preview(job=job, prompt=prompt)
            response_text = draft.text
        except (LLMProviderError, TimeoutError) as e:
            error = e
            draft = None
        ended_at = utc_now()
        duration_ms = int((time.perf_counter() - started_perf) * 1000)

        meta = self._build_meta(
            call_id=call_id,
            operation=operation,
            started_at=started_at.isoformat(),
            ended_at=ended_at.isoformat(),
            duration_ms=duration_ms,
            prompt=prompt,
            response=response_text,
            error=error,
        )
        artifacts = self._write_artifacts(
            job_id=job.job_id,
            call_id=call_id,
            prompt=prompt,
            response=response_text,
            meta=meta,
        )
        job.artifacts_index.extend(artifacts.as_list())

        logger.info(
            "SS_LLM_CALL_DONE",
            extra={
                "job_id": job.job_id,
                "llm_call_id": call_id,
                "operation": operation,
                "ok": meta["ok"],
            },
        )
        if draft is None:
            raise LLMCallFailedError(job_id=job.job_id, llm_call_id=call_id) from error
        return draft

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
    ) -> dict:
        error_message = None
        if error is not None:
            error_message = redact_text(str(error))
        seed = self._seed
        if isinstance(seed, str):
            seed = redact_text(seed)
        return {
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
            "prompt_fingerprint": _sha256_hex(prompt),
            "response_fingerprint": _sha256_hex(response),
            "prompt_token_estimate": _estimate_tokens(prompt),
            "response_token_estimate": _estimate_tokens(response),
            "error_type": None if error is None else type(error).__name__,
            "error_message": error_message,
        }

    def _write_artifacts(
        self,
        *,
        job_id: str,
        call_id: str,
        prompt: str,
        response: str,
        meta: dict,
    ) -> LLMCallArtifacts:
        rel_dir = PurePosixPath("artifacts") / "llm" / call_id
        prompt_rel = (rel_dir / "prompt.txt").as_posix()
        response_rel = (rel_dir / "response.txt").as_posix()
        meta_rel = (rel_dir / "meta.json").as_posix()
        try:
            self._write_text(job_id=job_id, rel_path=prompt_rel, text=redact_text(prompt))
            self._write_text(job_id=job_id, rel_path=response_rel, text=redact_text(response))
            self._write_json(job_id=job_id, rel_path=meta_rel, payload=meta)
        except (OSError, ValueError) as e:
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

    def _write_text(self, *, job_id: str, rel_path: str, text: str) -> None:
        path = self._safe_artifact_path(job_id=job_id, rel_path=rel_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def _write_json(self, *, job_id: str, rel_path: str, payload: dict) -> None:
        path = self._safe_artifact_path(job_id=job_id, rel_path=rel_path)
        path.parent.mkdir(parents=True, exist_ok=True)
        data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True)
        path.write_text(data, encoding="utf-8")

    def _safe_artifact_path(self, *, job_id: str, rel_path: str) -> Path:
        if not is_safe_job_rel_path(rel_path):
            raise ValueError("unsafe_rel_path")
        base = (self._jobs_dir / job_id).resolve(strict=False)
        resolved = (self._jobs_dir / job_id / rel_path).resolve(strict=False)
        if not resolved.is_relative_to(base):
            raise ValueError("symlink_escape")
        return resolved
