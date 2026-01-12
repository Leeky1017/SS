from __future__ import annotations

import logging
from typing import cast

from src.domain.audit import AuditContext, AuditLogger, NoopAuditLogger
from src.domain.idempotency import JobIdempotency
from src.domain.job_confirm_validation import validate_confirm_not_blocked
from src.domain.job_plan_freeze import freeze_plan_for_run
from src.domain.job_retry import retry_failed_job
from src.domain.job_store import JobStore
from src.domain.job_support import JobScheduler, emit_job_audit, new_trace_id
from src.domain.metrics import NoopMetrics, RuntimeMetrics
from src.domain.models import JOB_SCHEMA_VERSION_CURRENT, Job, JobInputs, JobStatus
from src.domain.output_formats import normalize_output_formats
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.exceptions import JobAlreadyExistsError
from src.utils.json_types import JsonObject, JsonValue
from src.utils.tenancy import DEFAULT_TENANT_ID
from src.utils.time import utc_now

logger = logging.getLogger(__name__)


class JobService:
    """Job lifecycle: create → confirm → queue."""

    def __init__(
        self,
        *,
        store: JobStore,
        scheduler: JobScheduler,
        plan_service: PlanService,
        state_machine: JobStateMachine,
        idempotency: JobIdempotency,
        metrics: RuntimeMetrics | None = None,
        audit: AuditLogger | None = None,
        audit_context: AuditContext | None = None,
    ):
        self._store = store
        self._scheduler = scheduler
        self._plan_service = plan_service
        self._state_machine = state_machine
        self._idempotency = idempotency
        self._metrics = NoopMetrics() if metrics is None else metrics
        self._audit = NoopAuditLogger() if audit is None else audit
        self._audit_context = (
            AuditContext.system(actor_id="unknown") if audit_context is None else audit_context
        )

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
        job = self._build_job(
            tenant_id=tenant_id,
            job_id=job_id,
            requirement=requirement,
            inputs_fingerprint=inputs_fingerprint,
        )
        try:
            self._store.create(tenant_id=tenant_id, job=job)
        except JobAlreadyExistsError:
            return self._load_existing_for_create(
                tenant_id=tenant_id, job_id=job_id, idempotency_key=idempotency_key
            )
        logger.info(
            "SS_JOB_CREATED",
            extra={"tenant_id": tenant_id, "job_id": job_id, "idempotency_key": idempotency_key},
        )
        self._metrics.record_job_created()
        emit_job_audit(
            audit=self._audit,
            audit_context=self._audit_context,
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
        notes: str | None = None,
        output_formats: list[str] | None = None,
        variable_corrections: dict[str, str] | None = None,
        answers: dict[str, JsonValue] | None = None,
        default_overrides: dict[str, JsonValue] | None = None,
        expert_suggestions_feedback: dict[str, JsonValue] | None = None,
    ) -> Job:
        if not confirmed:
            job = self._store.load(tenant_id=tenant_id, job_id=job_id)
            logger.info(
                "SS_JOB_CONFIRM_SKIPPED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "status": job.status.value},
            )
            emit_job_audit(
                audit=self._audit,
                audit_context=self._audit_context,
                action="job.confirm",
                tenant_id=tenant_id,
                job_id=job_id,
                result="noop",
                changes={"status": job.status.value},
                metadata={"confirmed": False},
            )
            return job
        validate_confirm_not_blocked(
            store=self._store,
            tenant_id=tenant_id,
            job_id=job_id,
            answers=answers,
        )
        updated = self.trigger_run(
            tenant_id=tenant_id,
            job_id=job_id,
            notes=notes,
            output_formats=output_formats,
            variable_corrections=variable_corrections,
            answers=answers,
            default_overrides=default_overrides,
            expert_suggestions_feedback=expert_suggestions_feedback,
        )
        logger.info(
            "SS_JOB_CONFIRMED",
            extra={"tenant_id": tenant_id, "job_id": job_id, "status": updated.status.value},
        )
        emit_job_audit(
            audit=self._audit,
            audit_context=self._audit_context,
            action="job.confirm",
            tenant_id=tenant_id,
            job_id=job_id,
            result="success",
            changes={"status": updated.status.value},
            metadata={"confirmed": True},
        )
        return updated

    def trigger_run(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        notes: str | None = None,
        output_formats: list[str] | None = None,
        variable_corrections: dict[str, str] | None = None,
        answers: dict[str, JsonValue] | None = None,
        default_overrides: dict[str, JsonValue] | None = None,
        expert_suggestions_feedback: dict[str, JsonValue] | None = None,
    ) -> Job:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        if job.status in {JobStatus.QUEUED, JobStatus.RUNNING, JobStatus.SUCCEEDED}:
            return self._run_idempotent_noop(job=job, tenant_id=tenant_id)
        if job.status == JobStatus.FAILED:
            return retry_failed_job(
                store=self._store,
                scheduler=self._scheduler,
                state_machine=self._state_machine,
                audit=self._audit,
                audit_context=self._audit_context,
                tenant_id=tenant_id,
                job=job,
                output_formats=output_formats,
            )
        job.output_formats = list(normalize_output_formats(output_formats))
        self._state_machine.ensure_transition(
            job_id=job_id,
            from_status=job.status,
            to_status=JobStatus.CONFIRMED,
        )
        freeze_plan_for_run(
            plan_service=self._plan_service,
            tenant_id=tenant_id,
            job_id=job_id,
            notes=notes,
            variable_corrections=variable_corrections,
            default_overrides=default_overrides,
            answers=answers,
            expert_suggestions_feedback=expert_suggestions_feedback,
        )
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        return self._queue_run(job=job, tenant_id=tenant_id)

    def _build_job(
        self,
        *,
        tenant_id: str,
        job_id: str,
        requirement: str | None,
        inputs_fingerprint: str | None,
    ) -> Job:
        inputs = None if inputs_fingerprint is None else JobInputs(fingerprint=inputs_fingerprint)
        return Job(
            schema_version=JOB_SCHEMA_VERSION_CURRENT,
            tenant_id=tenant_id,
            job_id=job_id,
            trace_id=new_trace_id(),
            status=JobStatus.CREATED,
            requirement=requirement,
            created_at=utc_now().isoformat(),
            inputs=inputs,
        )

    def _load_existing_for_create(
        self,
        *,
        tenant_id: str,
        job_id: str,
        idempotency_key: str,
    ) -> Job:
        existing = self._store.load(tenant_id=tenant_id, job_id=job_id)
        logger.info(
            "SS_JOB_CREATE_IDEMPOTENT_HIT",
            extra={"tenant_id": tenant_id, "job_id": job_id, "idempotency_key": idempotency_key},
        )
        emit_job_audit(
            audit=self._audit,
            audit_context=self._audit_context,
            action="job.create",
            tenant_id=tenant_id,
            job_id=job_id,
            result="noop",
            changes={"status": existing.status.value},
            metadata={"idempotency_key": idempotency_key},
        )
        return existing

    def _run_idempotent_noop(self, *, job: Job, tenant_id: str) -> Job:
        logger.info(
            "SS_JOB_RUN_IDEMPOTENT",
            extra={"tenant_id": tenant_id, "job_id": job.job_id, "status": job.status.value},
        )
        emit_job_audit(
            audit=self._audit,
            audit_context=self._audit_context,
            action="job.run.trigger",
            tenant_id=tenant_id,
            job_id=job.job_id,
            result="noop",
            changes={"status": job.status.value},
        )
        return job

    def _queue_run(self, *, job: Job, tenant_id: str) -> Job:
        transitions: list[JsonObject] = []
        start_status = job.status.value
        if self._state_machine.ensure_transition(
            job_id=job.job_id,
            from_status=job.status,
            to_status=JobStatus.CONFIRMED,
        ):
            transitions.append(
                {"from_status": job.status.value, "to_status": JobStatus.CONFIRMED.value}
            )
            job.status = JobStatus.CONFIRMED
        if self._state_machine.ensure_transition(
            job_id=job.job_id,
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
            extra={"tenant_id": tenant_id, "job_id": job.job_id, "status": job.status.value},
        )
        emit_job_audit(
            audit=self._audit,
            audit_context=self._audit_context,
            action="job.run.trigger",
            tenant_id=tenant_id,
            job_id=job.job_id,
            result="success",
            changes={
                "from_status": start_status,
                "to_status": job.status.value,
                "transitions": cast(JsonValue, transitions),
                "scheduled_at": job.scheduled_at,
            },
        )
        return job
