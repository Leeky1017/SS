from __future__ import annotations

import httpx
import pytest

from src.domain.stata_runner import RunError
from src.infra.stata_run_support import Execution
from tests.v1_redeem import redeem_job

pytestmark = pytest.mark.anyio


async def _upload_csv(*, client: httpx.AsyncClient, job_id: str) -> None:
    files = [("file", ("primary.csv", b"id,y,x\n1,2,3\n", "text/csv"))]
    response = await client.post(f"/v1/jobs/{job_id}/inputs/upload", files=files)
    assert response.status_code == 200


async def _confirm_ready_job(*, client: httpx.AsyncClient, task_code: str) -> str:
    job_id, _token = await redeem_job(client=client, task_code=task_code, requirement="req")
    await _upload_csv(client=client, job_id=job_id)
    preview = await client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert preview.status_code == 200
    patched = await client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200
    confirmed = await client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert confirmed.status_code == 200
    assert confirmed.json()["status"] == "queued"
    return job_id


async def test_execution_success_archives_artifacts_and_allows_download(
    e2e_client: httpx.AsyncClient,
    e2e_worker_service_factory,
) -> None:
    job_id = await _confirm_ready_job(client=e2e_client, task_code="tc_e2e_exec_ok")
    worker = e2e_worker_service_factory()
    assert worker.process_next(worker_id="worker_e2e") is True

    job = await e2e_client.get(f"/v1/jobs/{job_id}")
    assert job.status_code == 200
    assert job.json()["status"] == "succeeded"

    artifacts = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert artifacts.status_code == 200
    items = artifacts.json()["artifacts"]
    assert len(items) > 0

    meta = next(item for item in items if item["kind"] == "run.meta.json")
    rel_path = meta["rel_path"]
    downloaded = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts/{rel_path}")
    assert downloaded.status_code == 200
    assert b"job_id" in downloaded.content


async def test_execution_failure_then_retry_from_failed_requeues_and_succeeds(
    e2e_client: httpx.AsyncClient,
    e2e_worker_service_factory,
) -> None:
    job_id = await _confirm_ready_job(client=e2e_client, task_code="tc_e2e_exec_retry")
    worker = e2e_worker_service_factory(scripted_ok=[False, True])

    assert worker.process_next(worker_id="worker_e2e") is True
    failed = await e2e_client.get(f"/v1/jobs/{job_id}")
    assert failed.status_code == 200
    assert failed.json()["status"] == "failed"

    requeued = await e2e_client.post(f"/v1/jobs/{job_id}/run")
    assert requeued.status_code == 200
    assert requeued.json()["status"] == "queued"

    assert worker.process_next(worker_id="worker_e2e") is True
    done = await e2e_client.get(f"/v1/jobs/{job_id}")
    assert done.status_code == 200
    assert done.json()["status"] == "succeeded"


async def test_execution_timeout_marks_job_failed_and_records_error_artifact(
    e2e_client: httpx.AsyncClient,
    e2e_worker_service_factory,
) -> None:
    job_id = await _confirm_ready_job(client=e2e_client, task_code="tc_e2e_exec_timeout")
    timeout = Execution(
        stdout_text="",
        stderr_text="timeout",
        exit_code=None,
        timed_out=True,
        duration_ms=0,
        error=RunError(error_code="STATA_TIMEOUT", message="stata execution timed out"),
    )
    worker = e2e_worker_service_factory(scripted_executions=[timeout])
    assert worker.process_next(worker_id="worker_e2e") is True

    job = await e2e_client.get(f"/v1/jobs/{job_id}")
    assert job.status_code == 200
    assert job.json()["status"] == "failed"

    artifacts = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert artifacts.status_code == 200
    error_items = [
        item for item in artifacts.json()["artifacts"] if item["kind"] == "run.error.json"
    ]
    assert error_items
    error_rel = error_items[-1]["rel_path"]
    error = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts/{error_rel}")
    assert error.status_code == 200
    payload = error.json()
    assert payload["error_code"] == "STATA_TIMEOUT"
    assert payload["timed_out"] is True


async def test_execution_nonzero_exit_marks_job_failed_and_records_error_artifact(
    e2e_client: httpx.AsyncClient,
    e2e_worker_service_factory,
) -> None:
    job_id = await _confirm_ready_job(client=e2e_client, task_code="tc_e2e_exec_nonzero_exit")
    failed = Execution(
        stdout_text="fake stdout\n",
        stderr_text="syntax error",
        exit_code=198,
        timed_out=False,
        duration_ms=0,
        error=RunError(error_code="STATA_NONZERO_EXIT", message="stata exited with code 198"),
    )
    worker = e2e_worker_service_factory(scripted_executions=[failed])
    assert worker.process_next(worker_id="worker_e2e") is True

    job = await e2e_client.get(f"/v1/jobs/{job_id}")
    assert job.status_code == 200
    assert job.json()["status"] == "failed"

    artifacts = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert artifacts.status_code == 200
    error_items = [
        item for item in artifacts.json()["artifacts"] if item["kind"] == "run.error.json"
    ]
    assert error_items
    error_rel = error_items[-1]["rel_path"]
    error = await e2e_client.get(f"/v1/jobs/{job_id}/artifacts/{error_rel}")
    assert error.status_code == 200
    payload = error.json()
    assert payload["error_code"] == "STATA_NONZERO_EXIT"
    assert payload["exit_code"] == 198
