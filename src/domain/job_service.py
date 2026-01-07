from __future__ import annotations

import logging
import secrets
from collections import Counter
from dataclasses import dataclass
from typing import cast

from src.domain.audit import AuditContext, AuditEvent, AuditLogger, NoopAuditLogger
from src.domain.idempotency import JobIdempotency
from src.domain.job_store import JobStore
from src.domain.metrics import NoopMetrics, RuntimeMetrics
from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job, JobInputs, JobStatus
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobAlreadyExistsError
from src.utils.json_types import JsonObject, JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


def _new_trace_id() -> str:
    return secrets.token_hex(16)


class JobScheduler:
    def schedule(self, *, job: Job) -> None:
        raise NotImplementedError


@dataclass(frozen=True)
class NoopJobScheduler(JobScheduler):
    """Placeholder scheduler: records schedule intent only."""

    def schedule(self, *, job: Job) -> None:
        return None


class JobService:
    """Job lifecycle: create → confirm (queue/schedule)."""

    def __init__(
        self,
        *,
        store: JobStore,
        scheduler: JobScheduler,
        state_machine: JobStateMachine,
        idempotency: JobIdempotency,
        metrics: RuntimeMetrics | None = None,
        audit: AuditLogger | None = None,
        audit_context: AuditContext | None = None,
    ):
        self._store = store
        self._scheduler = scheduler
        self._state_machine = state_machine
        self._idempotency = idempotency
        self._metrics = NoopMetrics() if metrics is None else metrics
        self._audit = NoopAuditLogger() if audit is None else audit
        self._audit_context = (
            AuditContext.system(actor_id="unknown") if audit_context is None else audit_context
        )

    def _emit_audit(
        self,
        *,
        action: str,
        tenant_id: str,
        job_id: str,
        result: str,
        changes: JsonObject | None = None,
        metadata: JsonObject | None = None,
    ) -> None:
        final_meta: JsonObject = {"tenant_id": tenant_id}
        if metadata is not None:
            final_meta.update(metadata)
        event = AuditEvent(
            action=action,
            result=result,
            resource_type="job",
            resource_id=job_id,
            job_id=job_id,
            context=self._audit_context,
            changes=changes,
            metadata=final_meta,
        )
        self._audit.emit(event=event)

    def create_job(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        requirement: str | None,
        inputs_fingerprint: str | None = None,
        plan_revision: str | int | None = None,
    ) -> Job:
        idempotency_key = self._idempotency.compute_key(
            inputs_fingerprint=inputs_fingerprint,
            requirement=requirement,
            plan_revision=plan_revision,
        )
        job_id = self._idempotency.derive_job_id(idempotency_key=idempotency_key)
        inputs = None
        if inputs_fingerprint is not None:
            inputs = JobInputs(fingerprint=inputs_fingerprint)
        job = Job(
            schema_version=JOB_SCHEMA_VERSION_CURRENT,
            tenant_id=tenant_id,
            job_id=job_id,
            trace_id=_new_trace_id(),
            status=JobStatus.CREATED,
            requirement=requirement,
            created_at=utc_now().isoformat(),
            inputs=inputs,
        )
        try:
            self._store.create(tenant_id=tenant_id, job=job)
        except JobAlreadyExistsError:
            existing = self._store.load(tenant_id=tenant_id, job_id=job_id)
            logger.info(
                "SS_JOB_CREATE_IDEMPOTENT_HIT",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "idempotency_key": idempotency_key,
                },
            )
            self._emit_audit(
                action="job.create",
                tenant_id=tenant_id,
                job_id=job_id,
                result="noop",
                changes={"status": existing.status.value},
                metadata={"idempotency_key": idempotency_key},
            )
            return existing
        logger.info(
            "SS_JOB_CREATED",
            extra={"tenant_id": tenant_id, "job_id": job_id, "idempotency_key": idempotency_key},
        )
        self._metrics.record_job_created()
        self._emit_audit(
            action="job.create",
            tenant_id=tenant_id,
            job_id=job_id,
            result="success",
            changes={"status": job.status.value},
            metadata={"idempotency_key": idempotency_key},
        )
        return job

    def confirm_job(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        confirmed: bool,
    ) -> Job:
        if not confirmed:
            job = self._store.load(tenant_id=tenant_id, job_id=job_id)
            logger.info(
                "SS_JOB_CONFIRM_SKIPPED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "status": job.status.value},
            )
            self._emit_audit(
                action="job.confirm",
                tenant_id=tenant_id,
                job_id=job_id,
                result="noop",
                changes={"status": job.status.value},
                metadata={"confirmed": False},
            )
            return job
        updated = self.trigger_run(tenant_id=tenant_id, job_id=job_id)
        logger.info(
            "SS_JOB_CONFIRMED",
            extra={"tenant_id": tenant_id, "job_id": job_id, "status": updated.status.value},
        )
        self._emit_audit(
            action="job.confirm",
            tenant_id=tenant_id,
            job_id=job_id,
            result="success",
            changes={"status": updated.status.value},
            metadata={"confirmed": True},
        )
        return updated

    def trigger_run(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str) -> Job:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.status in {
            JobStatus.QUEUED,
            JobStatus.RUNNING,
            JobStatus.SUCCEEDED,
            JobStatus.FAILED,
        }:
            logger.info(
                "SS_JOB_RUN_IDEMPOTENT",
                extra={"tenant_id": tenant_id, "job_id": job_id, "status": job.status.value},
            )
            self._emit_audit(
                action="job.run.trigger",
                tenant_id=tenant_id,
                job_id=job_id,
                result="noop",
                changes={"status": job.status.value},
            )
            return job

        transitions: list[JsonObject] = []
        start_status = job.status.value
        if self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.CONFIRMED,
        ):
            transitions.append(
                {"from_status": job.status.value, "to_status": JobStatus.CONFIRMED.value}
            )
            job.status = JobStatus.CONFIRMED
        if self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.QUEUED,
        ):
            transitions.append(
                {"from_status": job.status.value, "to_status": JobStatus.QUEUED.value}
            )
            job.status = JobStatus.QUEUED
            if job.scheduled_at is None:
                job.scheduled_at = utc_now().isoformat()
            self._scheduler.schedule(job=job)
        self._store.save(tenant_id=tenant_id, job=job)
        logger.info(
            "SS_JOB_RUN_QUEUED",
            extra={"tenant_id": tenant_id, "job_id": job_id, "status": job.status.value},
        )
        self._emit_audit(
            action="job.run.trigger",
            tenant_id=tenant_id,
            job_id=job_id,
            result="success",
            changes={
                "from_status": start_status,
                "to_status": job.status.value,
                "transitions": cast(JsonValue, transitions),
                "scheduled_at": job.scheduled_at,
            },
        )
        return job

    def get_job_summary(self, *, tenant_id: str = DEFAULT_TENANT_ID, job_id: str) -> JsonObject:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        draft_summary: JsonObject | None = None
        if job.draft is not None:
            draft_summary = cast(
                JsonObject,
                {
                    "created_at": job.draft.created_at,
                    "text_chars": len(job.draft.text),
                },
            )

        kinds = Counter(ref.kind.value for ref in job.artifacts_index)
        artifacts_summary = {
            "total": len(job.artifacts_index),
            "by_kind": cast(JsonObject, dict(kinds)),
        }

        latest_run: JsonObject | None = None
        if job.runs:
            attempt = job.runs[-1]
            latest_run = cast(
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
