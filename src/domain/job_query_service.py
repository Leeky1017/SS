from __future__ import annotations

from collections import Counter
from typing import cast

from src.domain.job_store import JobStore
from src.domain.models import Job
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID


class JobQueryService:
    def __init__(self, *, store: JobStore):
        self._store = store

    def get_job_summary(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str) -> JsonObject:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        return _build_job_summary(job=job)


def _build_job_summary(*, job: Job) -> JsonObject:
    draft_summary = _draft_summary(job=job)
    artifacts_summary = _artifacts_summary(job=job)
    latest_run = _latest_run(job=job)
    return cast(
        JsonObject,
        {
            "job_id": job.job_id,
            "trace_id": job.trace_id,
            "status": job.status.value,
            "timestamps": {"created_at": job.created_at, "scheduled_at": job.scheduled_at},
            "draft": draft_summary,
            "artifacts": artifacts_summary,
            "latest_run": latest_run,
        },
    )


def _draft_summary(*, job: Job) -> JsonObject | None:
    if job.draft is None:
        return None
    return cast(
        JsonObject,
        {
            "created_at": job.draft.created_at,
            "text_chars": len(job.draft.text),
        },
    )


def _artifacts_summary(*, job: Job) -> JsonObject:
    kinds = Counter(ref.kind.value for ref in job.artifacts_index)
    return cast(
        JsonObject,
        {
            "total": len(job.artifacts_index),
            "by_kind": cast(JsonObject, dict(kinds)),
        },
    )


def _latest_run(*, job: Job) -> JsonObject | None:
    if not job.runs:
        return None
    attempt = job.runs[-1]
    return cast(
        JsonObject,
        {
            "run_id": attempt.run_id,
            "attempt": attempt.attempt,
            "status": attempt.status,
            "started_at": attempt.started_at,
            "ended_at": attempt.ended_at,
            "artifacts_count": len(attempt.artifacts),
        },
    )
