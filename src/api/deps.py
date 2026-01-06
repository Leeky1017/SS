from __future__ import annotations

from functools import lru_cache

from src.config import Config, load_config
from src.domain.draft_service import DraftService
from src.domain.job_service import JobScheduler, JobService, NoopJobScheduler
from src.domain.llm_client import LLMClient, StubLLMClient
from src.infra.job_store import JobStore


@lru_cache
def get_config() -> Config:
    return load_config()


@lru_cache
def get_job_store() -> JobStore:
    return JobStore(jobs_dir=get_config().jobs_dir)


@lru_cache
def get_llm_client() -> LLMClient:
    return StubLLMClient()


def get_job_scheduler() -> JobScheduler:
    return NoopJobScheduler()


def get_job_service() -> JobService:
    return JobService(store=get_job_store(), scheduler=get_job_scheduler())


def get_draft_service() -> DraftService:
    return DraftService(store=get_job_store(), llm=get_llm_client())
