from __future__ import annotations

import logging
from datetime import datetime
from typing import Callable

from src.domain.job_store import JobStore
from src.domain.models import Job, RunAttempt
from src.domain.stata_runner import RunResult

logger = logging.getLogger(__name__)


def record_attempt_started(
    *,
    job: Job,
    run_id: str,
    attempt: int,
    store: JobStore,
    clock: Callable[[], datetime],
) -> None:
    started_at = clock().isoformat()
    job.runs.append(
        RunAttempt(
            run_id=run_id,
            attempt=attempt,
            status="running",
            started_at=started_at,
            ended_at=None,
            artifacts=[],
        )
    )
    store.save(tenant_id=job.tenant_id, job=job)
    logger.info(
        "SS_WORKER_ATTEMPT_START",
        extra={
            "tenant_id": job.tenant_id,
            "job_id": job.job_id,
            "run_id": run_id,
            "attempt": attempt,
        },
    )


def record_attempt_finished(
    *,
    job: Job,
    run_id: str,
    result: RunResult,
    clock: Callable[[], datetime],
) -> None:
    ended_at = clock().isoformat()
    attempt = find_attempt(job=job, run_id=run_id)
    attempt.ended_at = ended_at
    attempt.status = "succeeded" if result.ok else "failed"
    attempt.artifacts = list(result.artifacts)
    index_artifacts(job=job, result=result)
    logger.info(
        "SS_WORKER_ATTEMPT_DONE",
        extra={"job_id": job.job_id, "run_id": run_id, "ok": result.ok},
    )


def find_attempt(*, job: Job, run_id: str) -> RunAttempt:
    for attempt in reversed(job.runs):
        if attempt.run_id == run_id:
            return attempt
    raise ValueError("run attempt not found")


def index_artifacts(*, job: Job, result: RunResult) -> None:
    known = {(ref.kind, ref.rel_path) for ref in job.artifacts_index}
    for ref in result.artifacts:
        key = (ref.kind, ref.rel_path)
        if key in known:
            continue
        job.artifacts_index.append(ref)
        known.add(key)
