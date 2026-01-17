from __future__ import annotations

from pathlib import Path
from typing import Any

from ss_ssh_e2e.audit_artifacts import verify_audit_artifacts
from ss_ssh_e2e.errors import E2EError, redact
from ss_ssh_e2e.http_trace import HttpTrace
from ss_ssh_e2e.v1_journey import redeem_and_build_headers, run_authed_journey

EXPECTED_LLM_MODEL = "claude-opus-4-5-20251101"


def require_httpx() -> Any:
    try:
        import httpx  # type: ignore[import-not-found]
    except ModuleNotFoundError as e:
        raise E2EError(
            event_code="SSE2E_LOCAL_DEP_MISSING",
            message="missing dependency: httpx (run via the SS repo venv)",
        ) from e
    return httpx


def poll_job(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    poll_interval_seconds: float,
    max_wait_seconds: float,
    trace: HttpTrace | None,
) -> dict[str, Any]:
    import time

    deadline = time.time() + max_wait_seconds
    with httpx.Client(base_url=base_url, headers=headers, timeout=30.0) as client:
        last: dict[str, Any] = {}
        polls = 0
        while time.time() < deadline:
            polls += 1
            resp = client.get(f"/v1/jobs/{job_id}")
            if resp.status_code != 200:
                time.sleep(poll_interval_seconds)
                continue
            last = resp.json()
            status = str(last.get("status", ""))
            if status in {"succeeded", "failed"}:
                if trace is not None:
                    trace.add(
                        method="GET",
                        path=f"/v1/jobs/{job_id}",
                        status_code=resp.status_code,
                        extra={"polls": polls, "terminal_status": status},
                    )
                return last
            time.sleep(poll_interval_seconds)
    raise E2EError(
        event_code="SSE2E_JOB_TIMEOUT",
        message=f"job did not reach terminal state within {max_wait_seconds}s",
        details={"job_id": job_id, "last": redact(last)},
    )


def run_flow(
    *,
    httpx: Any,
    base_url: str,
    out_dir: Path,
    tenant_id: str,
    task_code: str,
    requirement: str,
    ignore_unhealthy: bool,
    http_timeout_seconds: float,
    poll_interval_seconds: float,
    max_wait_seconds: float,
) -> dict[str, Any]:
    trace = HttpTrace()
    job_id, headers, redeem_payload = redeem_and_build_headers(
        httpx=httpx, base_url=base_url, tenant_id=tenant_id, task_code=task_code,
        requirement=requirement, ignore_unhealthy=ignore_unhealthy,
        http_timeout_seconds=http_timeout_seconds, trace=trace,
    )
    with httpx.Client(base_url=base_url, headers=headers, timeout=http_timeout_seconds) as authed:
        journey = run_authed_journey(client=authed, job_id=job_id, trace=trace)

    final_job = poll_job(
        httpx=httpx, base_url=base_url, headers=headers, job_id=job_id,
        poll_interval_seconds=poll_interval_seconds, max_wait_seconds=max_wait_seconds, trace=trace,
    )
    status = str(final_job.get("status", ""))
    artifacts = verify_audit_artifacts(
        httpx=httpx,
        base_url=base_url,
        headers=headers,
        job_id=job_id,
        out_dir=out_dir,
        status=status,
        expected_llm_model=EXPECTED_LLM_MODEL,
        trace=trace,
    )

    return {
        "task_code": task_code,
        "job_id": job_id,
        "status": status,
        "tenant_id": tenant_id,
        "expected_llm_model": EXPECTED_LLM_MODEL,
        "redeem": redact(redeem_payload),
        "journey": journey,
        "http_trace": trace.calls,
        "final_job": redact(final_job),
        **artifacts,
    }
