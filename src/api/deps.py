from __future__ import annotations

from functools import lru_cache

from src.config import Config, load_config
from src.domain.artifacts_service import ArtifactsService
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobScheduler, JobService
from src.domain.job_store import JobStore
from src.domain.llm_client import LLMClient, StubLLMClient
from src.domain.state_machine import JobStateMachine
from src.infra.file_worker_queue import FileWorkerQueue
from src.infra.job_store_factory import build_job_store
from src.infra.llm_tracing import TracedLLMClient
from src.infra.queue_job_scheduler import QueueJobScheduler


@lru_cache
def get_config() -> Config:
    return load_config()


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


def get_job_scheduler() -> JobScheduler:
    return QueueJobScheduler(queue=get_worker_queue())


def get_job_service() -> JobService:
    return JobService(
        store=get_job_store(),
        scheduler=get_job_scheduler(),
        state_machine=get_job_state_machine(),
        idempotency=get_job_idempotency(),
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
