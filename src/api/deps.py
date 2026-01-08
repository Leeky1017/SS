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
def _config_cached() -> Config:
    return load_config()


async def get_config() -> Config:
    return _config_cached()


async def get_tenant_id(
    x_ss_tenant_id: str | None = Header(default=None, alias="X-SS-Tenant-ID"),
) -> str:
    if x_ss_tenant_id is None:
        return DEFAULT_TENANT_ID
    tenant_id = x_ss_tenant_id.strip()
    if tenant_id == "":
        raise HTTPException(status_code=400, detail="X-SS-Tenant-ID must not be empty")
    if not is_safe_tenant_id(tenant_id):
        raise HTTPException(status_code=400, detail="X-SS-Tenant-ID is not a safe path segment")
    return tenant_id


@lru_cache
def _job_store_cached() -> JobStore:
    return build_job_store(config=_config_cached())


async def get_job_store() -> JobStore:
    return _job_store_cached()


@lru_cache
def _worker_queue_cached() -> FileWorkerQueue:
    config = _config_cached()
    return FileWorkerQueue(
        queue_dir=config.queue_dir,
        lease_ttl_seconds=config.queue_lease_ttl_seconds,
    )


@lru_cache
def _llm_client_cached() -> LLMClient:
    config = _config_cached()
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
def _job_state_machine_cached() -> JobStateMachine:
    return JobStateMachine()


@lru_cache
def _job_idempotency_cached() -> JobIdempotency:
    return JobIdempotency()


@lru_cache
def _metrics_cached() -> PrometheusMetrics:
    return PrometheusMetrics()


def get_metrics_sync() -> PrometheusMetrics:
    return _metrics_cached()


@lru_cache
def _audit_logger_cached() -> AuditLogger:
    return LoggingAuditLogger()


@lru_cache
def _job_scheduler_cached() -> JobScheduler:
    return QueueJobScheduler(queue=_worker_queue_cached())


async def get_worker_queue() -> FileWorkerQueue:
    return _worker_queue_cached()


async def get_llm_client() -> LLMClient:
    return _llm_client_cached()


async def get_job_state_machine() -> JobStateMachine:
    return _job_state_machine_cached()


async def get_job_idempotency() -> JobIdempotency:
    return _job_idempotency_cached()


async def get_metrics() -> PrometheusMetrics:
    return _metrics_cached()


async def get_runtime_metrics() -> RuntimeMetrics:
    return _metrics_cached()


async def get_audit_logger() -> AuditLogger:
    return _audit_logger_cached()


async def get_job_scheduler() -> JobScheduler:
    return _job_scheduler_cached()


async def get_job_service(audit_ctx: AuditContext = Depends(get_audit_context)) -> JobService:
    return JobService(
        store=_job_store_cached(),
        scheduler=_job_scheduler_cached(),
        plan_service=_plan_service_cached(),
        state_machine=_job_state_machine_cached(),
        idempotency=_job_idempotency_cached(),
        metrics=_metrics_cached(),
        audit=_audit_logger_cached(),
        audit_context=audit_ctx,
    )


@lru_cache
def _artifacts_service_cached() -> ArtifactsService:
    config = _config_cached()
    return ArtifactsService(store=_job_store_cached(), jobs_dir=config.jobs_dir)


async def get_artifacts_service() -> ArtifactsService:
    return _artifacts_service_cached()


async def get_draft_service() -> DraftService:
    return DraftService(
        store=_job_store_cached(),
        llm=_llm_client_cached(),
        state_machine=_job_state_machine_cached(),
    )


@lru_cache
def _job_workspace_store_cached() -> JobWorkspaceStore:
    return FileJobWorkspaceStore(jobs_dir=_config_cached().jobs_dir)


@lru_cache
def _job_inputs_service_cached() -> JobInputsService:
    return JobInputsService(store=_job_store_cached(), workspace=_job_workspace_store_cached())


@lru_cache
def _job_query_service_cached() -> JobQueryService:
    return JobQueryService(store=_job_store_cached())


@lru_cache
def _plan_service_cached() -> PlanService:
    return PlanService(store=_job_store_cached(), workspace=_job_workspace_store_cached())


async def get_job_workspace_store() -> JobWorkspaceStore:
    return _job_workspace_store_cached()


async def get_job_inputs_service() -> JobInputsService:
    return _job_inputs_service_cached()


async def get_job_query_service() -> JobQueryService:
    return _job_query_service_cached()


async def get_plan_service() -> PlanService:
    return _plan_service_cached()


def clear_dependency_caches() -> None:
    _config_cached.cache_clear()
    _job_store_cached.cache_clear()
    _worker_queue_cached.cache_clear()
    _llm_client_cached.cache_clear()
    _job_state_machine_cached.cache_clear()
    _job_idempotency_cached.cache_clear()
    _metrics_cached.cache_clear()
    _audit_logger_cached.cache_clear()
    _job_scheduler_cached.cache_clear()
    _artifacts_service_cached.cache_clear()
    _job_workspace_store_cached.cache_clear()
    _job_inputs_service_cached.cache_clear()
    _job_query_service_cached.cache_clear()
    _plan_service_cached.cache_clear()
