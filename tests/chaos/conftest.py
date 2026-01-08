from __future__ import annotations

import errno
from collections.abc import Callable
from pathlib import Path

import httpx
import pytest

from src.api import deps
from src.domain.job_query_service import JobQueryService
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir
from tests.asgi_client import asgi_client
from tests.async_overrides import async_override


@pytest.fixture
def enospc_error() -> OSError:
    return OSError(errno.ENOSPC, "No space left on device")


@pytest.fixture
def job_dir_for(jobs_dir: Path) -> Callable[[str], Path]:
    def _resolve(job_id: str) -> Path:
        job_dir = resolve_job_dir(jobs_dir=jobs_dir, job_id=job_id)
        assert job_dir is not None
        return job_dir

    return _resolve


@pytest.fixture
def app(job_service, draft_service, store):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = async_override(job_service)
    app.dependency_overrides[deps.get_job_query_service] = async_override(
        JobQueryService(store=store)
    )
    app.dependency_overrides[deps.get_draft_service] = async_override(draft_service)
    return app


@pytest.fixture
async def client(app) -> httpx.AsyncClient:
    async with asgi_client(app=app) as client:
        yield client
