from __future__ import annotations

import hashlib
import secrets
from collections.abc import Callable
from dataclasses import dataclass
from datetime import datetime, timedelta

from src.domain.job_store import JobStore
from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job, JobStatus
from src.infra.auth_exceptions import TaskCodeInvalidError, TaskCodeRedeemConflictError
from src.infra.exceptions import JobAlreadyExistsError, JobNotFoundError
from src.utils.tenancy import DEFAULT_TENANT_ID

TOKEN_TTL_DAYS = 7
TOKEN_PREFIX = "ssv1"


@dataclass(frozen=True)
class TaskCodeRedeemResult:
    job_id: str
    token: str
    expires_at: str
    is_idempotent: bool


class TaskCodeRedeemService:
    def __init__(self, *, store: JobStore, now: Callable[[], datetime]):
        self._store = store
        self._now = now

    def redeem(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        task_code: str,
        requirement: str,
    ) -> TaskCodeRedeemResult:
        normalized_task_code = task_code.strip()
        if normalized_task_code == "":
            raise TaskCodeInvalidError()
        job_id = _derive_job_id(task_code=normalized_task_code)
        now = self._now()
        expires_at = _expires_at(now=now)

        job, is_idempotent = self._load_or_create_job(
            tenant_id=tenant_id,
            task_code=normalized_task_code,
            requirement=requirement,
            now=now,
        )
        if is_idempotent:
            job.auth_expires_at = expires_at
            self._store.save(tenant_id=tenant_id, job=job)
        return TaskCodeRedeemResult(
            job_id=job_id,
            token=str(job.auth_token),
            expires_at=expires_at,
            is_idempotent=is_idempotent,
        )

    def _load_or_create_job(
        self,
        *,
        tenant_id: str,
        task_code: str,
        requirement: str,
        now: datetime,
    ) -> tuple[Job, bool]:
        job_id = _derive_job_id(task_code=task_code)
        try:
            job = self._store.load(tenant_id=tenant_id, job_id=job_id)
            _assert_task_code_matches(job=job, task_code=task_code)
            _assert_token_present(job=job)
            return job, True
        except JobNotFoundError:
            job = _new_job(tenant_id=tenant_id, job_id=job_id, requirement=requirement, now=now)
            job.redeem_task_code = task_code
            job.auth_token = _new_token(job_id=job_id)
            job.auth_expires_at = _expires_at(now=now)
            try:
                self._store.create(tenant_id=tenant_id, job=job)
            except JobAlreadyExistsError:
                existing = self._store.load(tenant_id=tenant_id, job_id=job_id)
                _assert_task_code_matches(job=existing, task_code=task_code)
                _assert_token_present(job=existing)
                return existing, True
            return job, False


def _derive_job_id(*, task_code: str) -> str:
    digest = hashlib.sha256(task_code.encode("utf-8")).hexdigest()
    return f"job_tc_{digest[:16]}"


def _new_token(*, job_id: str) -> str:
    secret = secrets.token_hex(16)
    return f"{TOKEN_PREFIX}.{job_id}.{secret}"


def _expires_at(*, now: datetime) -> str:
    return (now + timedelta(days=TOKEN_TTL_DAYS)).isoformat()


def _new_job(*, tenant_id: str, job_id: str, requirement: str, now: datetime) -> Job:
    persisted_requirement = None if requirement.strip() == "" else requirement
    return Job(
        schema_version=JOB_SCHEMA_VERSION_CURRENT,
        tenant_id=tenant_id,
        job_id=job_id,
        trace_id=secrets.token_hex(16),
        status=JobStatus.CREATED,
        requirement=persisted_requirement,
        created_at=now.isoformat(),
    )


def _assert_token_present(*, job: Job) -> None:
    token = getattr(job, "auth_token", None)
    if not isinstance(token, str) or token.strip() == "":
        raise TaskCodeRedeemConflictError()


def _assert_task_code_matches(*, job: Job, task_code: str) -> None:
    stored = getattr(job, "redeem_task_code", None)
    if stored is None:
        raise TaskCodeRedeemConflictError()
    if stored != task_code:
        raise TaskCodeRedeemConflictError()
