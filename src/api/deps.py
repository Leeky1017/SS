from __future__ import annotations

from functools import lru_cache

from fastapi import Depends, Header, HTTPException

from src.api.audit_context import get_audit_context
from src.config import Config, load_config
from src.domain.artifacts_service import ArtifactsService
from src.domain.audit import AuditContext, AuditLogger
from src.domain.do_template_selection_service import DoTemplateSelectionService
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_inputs_service import JobInputsService
from src.domain.job_query_service import JobQueryService
from src.domain.job_service import JobService
from src.domain.job_store import JobStore
from src.domain.job_support import JobScheduler
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.llm_client import LLMClient
from src.domain.metrics import RuntimeMetrics
from src.domain.object_store import ObjectStore
from src.domain.plan_service import PlanService
from src.domain.state_machine import JobStateMachine
from src.domain.task_code_redeem_service import TaskCodeRedeemService
from src.domain.upload_bundle_service import UploadBundleService
from src.domain.upload_sessions_service import UploadSessionsService
from src.infra.audit_logger import LoggingAuditLogger
from src.infra.file_job_workspace_store import FileJobWorkspaceStore
from src.infra.file_task_code_store import FileTaskCodeStore
from src.infra.file_upload_session_store import FileUploadSessionStore
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository
from src.infra.job_store_factory import build_job_store
from src.infra.llm_client_factory import build_llm_client
from src.infra.object_store_factory import build_object_store
from src.infra.prometheus_metrics import PrometheusMetrics
from src.infra.queue_job_scheduler import QueueJobScheduler
from src.utils.tenancy import DEFAULT_TENANT_ID, is_safe_tenant_id
from src.utils.time import utc_now


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
    return build_llm_client(config=_config_cached())


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
        scheduler=_job_scheduler_cached(), plan_service=_plan_service_cached(),
        state_machine=_job_state_machine_cached(), idempotency=_job_idempotency_cached(),
        metrics=_metrics_cached(), audit=_audit_logger_cached(), audit_context=audit_ctx,
    )


@lru_cache
def _artifacts_service_cached() -> ArtifactsService:
    config = _config_cached()
    return ArtifactsService(store=_job_store_cached(), jobs_dir=config.jobs_dir)


async def get_artifacts_service() -> ArtifactsService:
    return _artifacts_service_cached()


async def get_draft_service() -> DraftService:
    return DraftService(
        store=_job_store_cached(), llm=_llm_client_cached(),
        state_machine=_job_state_machine_cached(), workspace=_job_workspace_store_cached(),
        do_template_selection=_do_template_selection_service_cached(),
    )


@lru_cache
def _job_workspace_store_cached() -> JobWorkspaceStore:
    return FileJobWorkspaceStore(jobs_dir=_config_cached().jobs_dir)


@lru_cache
def _do_template_catalog_cached() -> FileSystemDoTemplateCatalog:
    return FileSystemDoTemplateCatalog(library_dir=_config_cached().do_template_library_dir)


@lru_cache
def _do_template_selection_service_cached() -> DoTemplateSelectionService:
    return DoTemplateSelectionService(
        store=_job_store_cached(),
        llm=_llm_client_cached(),
        catalog=_do_template_catalog_cached(),
    )


@lru_cache
def _job_inputs_service_cached() -> JobInputsService:
    return JobInputsService(store=_job_store_cached(), workspace=_job_workspace_store_cached())


@lru_cache
def _job_query_service_cached() -> JobQueryService:
    return JobQueryService(store=_job_store_cached())


@lru_cache
def _plan_service_cached() -> PlanService:
    config = _config_cached()
    return PlanService(
        store=_job_store_cached(), workspace=_job_workspace_store_cached(),
        do_template_catalog=FileSystemDoTemplateCatalog(library_dir=config.do_template_library_dir),
        do_template_repo=FileSystemDoTemplateRepository(library_dir=config.do_template_library_dir),
    )


async def get_job_workspace_store() -> JobWorkspaceStore:
    return _job_workspace_store_cached()


async def get_job_inputs_service() -> JobInputsService:
    return _job_inputs_service_cached()


@lru_cache
def _upload_bundle_service_cached() -> UploadBundleService:
    config = _config_cached()
    return UploadBundleService(
        workspace=_job_workspace_store_cached(),
        max_bundle_files=config.upload_max_bundle_files,
    )


async def get_upload_bundle_service() -> UploadBundleService:
    return _upload_bundle_service_cached()


@lru_cache
def _object_store_cached() -> ObjectStore:
    return build_object_store(config=_config_cached())


async def get_object_store() -> ObjectStore:
    return _object_store_cached()


@lru_cache
def _upload_session_store_cached() -> FileUploadSessionStore:
    config = _config_cached()
    return FileUploadSessionStore(jobs_dir=config.jobs_dir)


@lru_cache
def _upload_sessions_service_cached() -> UploadSessionsService:
    return UploadSessionsService(
        config=_config_cached(), store=_job_store_cached(), workspace=_job_workspace_store_cached(),
        object_store=_object_store_cached(), bundle_service=_upload_bundle_service_cached(),
        session_store=_upload_session_store_cached(),
    )


async def get_upload_sessions_service() -> UploadSessionsService:
    return _upload_sessions_service_cached()


async def get_job_query_service() -> JobQueryService:
    return _job_query_service_cached()


async def get_plan_service() -> PlanService:
    return _plan_service_cached()


@lru_cache
def _task_code_redeem_service_cached() -> TaskCodeRedeemService:
    return TaskCodeRedeemService(
        store=_job_store_cached(), now=utc_now,
        task_codes=FileTaskCodeStore(data_dir=_config_cached().admin_data_dir),
    )


async def get_task_code_redeem_service() -> TaskCodeRedeemService:
    return _task_code_redeem_service_cached()


def clear_dependency_caches() -> None:
    for cache in (
        _config_cached, _job_store_cached, _worker_queue_cached, _llm_client_cached,
        _job_state_machine_cached, _job_idempotency_cached, _metrics_cached, _audit_logger_cached,
        _job_scheduler_cached, _artifacts_service_cached, _job_workspace_store_cached,
        _do_template_catalog_cached, _do_template_selection_service_cached,
        _job_inputs_service_cached, _upload_bundle_service_cached, _object_store_cached,
        _upload_session_store_cached, _upload_sessions_service_cached, _job_query_service_cached,
        _plan_service_cached, _task_code_redeem_service_cached,
    ):
        cache.cache_clear()
