from __future__ import annotations

import errno
from collections.abc import Callable
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from src.api import deps
from src.main import create_app
from src.utils.job_workspace import resolve_job_dir


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
def app(job_service, draft_service):
    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: job_service
    app.dependency_overrides[deps.get_draft_service] = lambda: draft_service
    return app


@pytest.fixture
def client(app) -> TestClient:
    return TestClient(app)

