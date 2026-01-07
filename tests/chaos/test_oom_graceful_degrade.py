from __future__ import annotations

import logging

from fastapi.testclient import TestClient

from src.api import deps
from src.main import create_app
from src.utils.tenancy import DEFAULT_TENANT_ID


def test_create_job_when_oom_returns_user_friendly_error(caplog) -> None:
    class OOMJobService:
        def create_job(self, *, tenant_id: str = DEFAULT_TENANT_ID, requirement: str | None):  # noqa: ANN001
            raise MemoryError("simulated oom")

    app = create_app()
    app.dependency_overrides[deps.get_job_service] = lambda: OOMJobService()
    client = TestClient(app)

    with caplog.at_level(logging.ERROR):
        response = client.post("/v1/jobs", json={"requirement": "hello"})

    assert response.status_code == 503
    payload = response.json()
    assert payload["error_code"] == "RESOURCE_OOM"
    assert "Traceback" not in payload["message"]

    records = [r for r in caplog.records if r.msg == "SS_RESOURCE_OOM"]
    assert len(records) == 1
