from __future__ import annotations

from functools import lru_cache

from fastapi import Depends, Header, HTTPException

from src.api.audit_context import get_audit_context
from src.config import Config, load_config
from src.domain.artifacts_service import ArtifactsService
from src.domain.audit import AuditContext, AuditLogger
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobScheduler, JobService
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient, StubLLMClient
from src.domain.metrics import RuntimeMetrics
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.infra.audit_logger import LoggingAuditLogger
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store_factory import build_job_store
from src.infra.llm_tracing import TracedLLMClient
from src.infra.prometheus_metrics import PrometheusMetrics
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.utils.tenancy import DEFAULT_TENANT_ID, is_safe_tenant_id


@lru_cache
def get_config() -> Config:
    return load_config()


def get_tenant_id(x_ss_tenant_id: str | None = Header(default=None, alias="X-SS-Tenant-ID")) -> str:
    if x_ss_tenant_id is None:
        return DEFAULT_TENANT_ID
    tenant_id = x_ss_tenant_id.strip()
    if tenant_id == "":
        raise HTTPException(status_code=400, detail="X-SS-Tenant-ID must not be empty")
    if not is_safe_tenant_id(tenant_id):
        raise HTTPException(status_code=400, detail="X-SS-Tenant-ID is not a safe path segment")
    return tenant_id


@lru_cache
def get_job_store() -> JobStore:
    return build_job_store(config=get_config())


@lru_cache
def get_worker_queue() -> FileWorkerQueue:
    config = get_config()
    return FileWorkerQueue(
        queue_dir=config.queue_dir,
        lease_ttl_seconds=config.queue_lease_ttl_seconds,
    )


@lru_cache
def get_llm_client() -> LLMClient:
    config = get_config()
    return TracedLLMClient(
        inner=StubLLMClient(),
        jobs_dir=config.jobs_dir,
        model="stub",
        temperature=0.0,
        seed=None,
        timeout_seconds=config.llm_timeout_seconds,
        max_attempts=config.llm_max_attempts,
        retry_backoff_base_seconds=config.llm_retry_backoff_base_seconds,
        retry_backoff_max_seconds=config.llm_retry_backoff_max_seconds,
    )


@lru_cache
def get_job_state_machine() -> JobStateMachine:
    return JobStateMachine()


@lru_cache
def get_job_idempotency() -> JobIdempotency:
    return JobIdempotency()


@lru_cache
def get_metrics() -> PrometheusMetrics:
    return PrometheusMetrics()


def get_runtime_metrics() -> RuntimeMetrics:
    return get_metrics()


@lru_cache
def get_audit_logger() -> AuditLogger:
    return LoggingAuditLogger()


def get_job_scheduler() -> JobScheduler:
    return QueueJobScheduler(queue=get_worker_queue())


def get_job_service(audit_ctx: AuditContext = Depends(get_audit_context)) -> JobService:
    return JobService(
        store=get_job_store(),
        scheduler=get_job_scheduler(),
        plan_service=get_plan_service(),
        state_machine=get_job_state_machine(),
        idempotency=get_job_idempotency(),
        metrics=get_runtime_metrics(),
        audit=get_audit_logger(),
        audit_context=audit_ctx,
    )


@lru_cache
def get_artifacts_service() -> ArtifactsService:
    return ArtifactsService(store=get_job_store(), jobs_dir=get_config().jobs_dir)


def get_draft_service() -> DraftService:
    return DraftService(
        store=get_job_store(),
        llm=get_llm_client(),
        state_machine=get_job_state_machine(),
    )


@lru_cache
def get_job_workspace_store() -> JobWorkspaceStore:
    return FileJobWorkspaceStore(jobs_dir=get_config().jobs_dir)


@lru_cache
def get_job_inputs_service() -> JobInputsService:
    return JobInputsService(store=get_job_store(), workspace=get_job_workspace_store())


@lru_cache
def get_job_query_service() -> JobQueryService:
    return JobQueryService(store=get_job_store())


@lru_cache
def get_plan_service() -> PlanService:
    return PlanService(store=get_job_store(), workspace=get_job_workspace_store())
