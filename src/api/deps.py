from __future__ import annotations

from functools import lru_cache

from src.config import Config, load_config
from src.domain.draft_service import DraftService
from src.domain.idempotency import JobIdempotency
from src.domain.job_service import JobScheduler, JobService, NoopJobScheduler
from src.domain.llm_client import LLMClient, StubLLMClient
from src.domain.state_machine import JobStateMachine
from src.infra.job_store import JobStore
from src.infra.llm_tracing import TracedLLMClient


@lru_cache
def get_config() -> Config:
    return load_config()


@lru_cache
def get_job_store() -> JobStore:
    return JobStore(jobs_dir=get_config().jobs_dir)


@lru_cache
def get_llm_client() -> LLMClient:
    return TracedLLMClient(
        inner=StubLLMClient(),
        jobs_dir=get_config().jobs_dir,
        model="stub",
        temperature=0.0,
        seed=None,
    )


@lru_cache
def get_job_state_machine() -> JobStateMachine:
    return JobStateMachine()


@lru_cache
def get_job_idempotency() -> JobIdempotency:
    return JobIdempotency()


def get_job_scheduler() -> JobScheduler:
    return NoopJobScheduler()


def get_job_service() -> JobService:
    return JobService(
        store=get_job_store(),
        scheduler=get_job_scheduler(),
        state_machine=get_job_state_machine(),
        idempotency=get_job_idempotency(),
    )


def get_draft_service() -> DraftService:
    return DraftService(
        store=get_job_store(),
        llm=get_llm_client(),
        state_machine=get_job_state_machine(),
    )
