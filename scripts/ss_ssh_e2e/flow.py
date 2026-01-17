from __future__ import annotations

import json
from pathlib import Path
from typing import Any
from urllib.parse import quote

from ss_ssh_e2e.errors import (
    E2EError,
    json_dumps,
    redact,
    safe_posix_rel_path,
    write_bytes,
    write_text,
)


def require_httpx() -> Any:
    try:
        import httpx  # type: ignore[import-not-found]
    except ModuleNotFoundError as e:
        raise E2EError(
            event_code="SSE2E_LOCAL_DEP_MISSING",
            message="missing dependency: httpx (run via the SS repo venv)",
        ) from e
    return httpx


def http_json(resp: Any) -> Any:
    try:
        return resp.json()
    except ValueError:
        return {"_raw": resp.text}


def assert_status(resp: Any, *, expected: int, context: str) -> None:
    if resp.status_code == expected:
        return
    raise E2EError(
        event_code="SSE2E_HTTP_UNEXPECTED",
        message=f"{context}: status={resp.status_code}",
        details={"body": redact(http_json(resp))},
    )


def poll_job(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    poll_interval_seconds: float,
    max_wait_seconds: float,
) -> dict[str, Any]:
    import time

    deadline = time.time() + max_wait_seconds
    with httpx.Client(base_url=base_url, headers=headers, timeout=30.0) as client:
        last: dict[str, Any] = {}
        while time.time() < deadline:
            resp = client.get(f"/v1/jobs/{job_id}")
            if resp.status_code != 200:
                time.sleep(poll_interval_seconds)
                continue
            last = resp.json()
            status = str(last.get("status", ""))
            if status in {"succeeded", "failed"}:
                return last
            time.sleep(poll_interval_seconds)
    raise E2EError(
        event_code="SSE2E_JOB_TIMEOUT",
        message=f"job did not reach terminal state within {max_wait_seconds}s",
        details={"job_id": job_id, "last": redact(last)},
    )


def pick_last_artifact(*, artifacts: list[dict[str, Any]], kind: str) -> dict[str, Any] | None:
    for item in reversed(artifacts):
        if str(item.get("kind", "")) == kind:
            return item
    return None


def download_artifact(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    rel_path: str,
    out_dir: Path,
) -> Path:
    safe_rel = safe_posix_rel_path(rel_path)
    url_path = quote(rel_path, safe="/")
    with httpx.Client(base_url=base_url, headers=headers, timeout=120.0) as client:
        resp = client.get(f"/v1/jobs/{job_id}/artifacts/{url_path}")
    assert_status(resp, expected=200, context=f"download artifact {rel_path}")
    local = out_dir / "artifacts" / Path(str(safe_rel))
    write_bytes(local, resp.content)
    return local


def domain_guess_from_error_code(error_code: str) -> str:
    prefix = error_code.split("_", 1)[0]
    return {
        "LLM": "llm",
        "STATA": "stata",
        "INPUT": "inputs",
        "ARTIFACT": "api",
        "AUTH": "api",
        "JOB": "worker/queue",
        "QUEUE": "worker/queue",
    }.get(prefix, "unknown")


def check_health(*, client: Any, ignore_unhealthy: bool) -> None:
    ready = client.get("/health/ready")
    if ready.status_code not in {200, 503}:
        raise E2EError(
            event_code="SSE2E_HEALTH_BAD_RESPONSE",
            message=f"GET /health/ready status={ready.status_code}",
        )
    if ready.status_code == 503 and not ignore_unhealthy:
        raise E2EError(
            event_code="SSE2E_HEALTH_UNHEALTHY",
            message="/health/ready unhealthy",
            details={"health": redact(http_json(ready))},
        )


def redeem_task_code(*, client: Any, task_code: str, requirement: str) -> tuple[str, str]:
    redeem = client.post(
        "/v1/task-codes/redeem",
        json={"task_code": task_code, "requirement": requirement},
    )
    assert_status(redeem, expected=200, context="redeem task code")
    payload = redeem.json()
    job_id = str(payload.get("job_id", ""))
    token = str(payload.get("token", ""))
    if not job_id.startswith("job_") or not token.startswith("ssv1."):
        raise E2EError(
            event_code="SSE2E_REDEEM_BAD_PAYLOAD",
            message="unexpected redeem payload",
            details={"payload": redact(payload)},
        )
    return job_id, token


def upload_inputs(*, client: Any, job_id: str) -> None:
    csv_bytes = b"id,y,x\n1,2,3\n2,4,6\n"
    upload = client.post(
        f"/v1/jobs/{job_id}/inputs/upload",
        files={"file": ("primary.csv", csv_bytes, "text/csv")},
    )
    assert_status(upload, expected=200, context="inputs upload")


def preview_inputs(*, client: Any, job_id: str) -> None:
    preview = client.get(f"/v1/jobs/{job_id}/inputs/preview")
    assert_status(preview, expected=200, context="inputs preview")


def draft_preview(*, client: Any, job_id: str) -> None:
    draft = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert_status(draft, expected=200, context="draft preview (LLM)")


def draft_patch(*, client: Any, job_id: str) -> None:
    patched = client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert_status(patched, expected=200, context="draft patch")


def confirm_job(*, client: Any, job_id: str) -> None:
    confirm = client.post(
        f"/v1/jobs/{job_id}/confirm",
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert_status(confirm, expected=200, context="confirm")


def run_authed_journey(*, client: Any, job_id: str) -> None:
    upload_inputs(client=client, job_id=job_id)
    preview_inputs(client=client, job_id=job_id)
    draft_preview(client=client, job_id=job_id)
    draft_patch(client=client, job_id=job_id)
    confirm_job(client=client, job_id=job_id)


def fetch_artifacts_index(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
) -> dict[str, Any]:
    with httpx.Client(base_url=base_url, headers=headers, timeout=120.0) as authed:
        artifacts_resp = authed.get(f"/v1/jobs/{job_id}/artifacts")
        assert_status(artifacts_resp, expected=200, context="artifacts index")
        return artifacts_resp.json()


def _read_json_file(path: Path) -> dict[str, Any] | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def extract_artifacts_list(payload: dict[str, Any]) -> list[dict[str, Any]]:
    artifacts = payload.get("artifacts", [])
    if not isinstance(artifacts, list):
        raise E2EError(
            event_code="SSE2E_ARTIFACTS_BAD_PAYLOAD",
            message="artifacts payload missing artifacts list",
        )
    return [item for item in artifacts if isinstance(item, dict)]


def required_kinds_for_status(status: str) -> list[str]:
    required = ["stata.do", "stata.log", "run.meta.json"]
    if status == "failed":
        return ["run.error.json", *required]
    return required


def download_required_artifacts(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    out_dir: Path,
    artifacts: list[dict[str, Any]],
    required_kinds: list[str],
) -> tuple[dict[str, str], dict[str, Any] | None]:
    downloaded: dict[str, str] = {}
    run_error: dict[str, Any] | None = None
    missing: list[str] = []
    for kind in required_kinds:
        item = pick_last_artifact(artifacts=artifacts, kind=kind)
        rel_path = str(item.get("rel_path", "")) if isinstance(item, dict) else ""
        if rel_path == "":
            missing.append(kind)
            continue
        local = download_artifact(
            httpx=httpx,
            base_url=base_url,
            headers=headers,
            job_id=job_id,
            rel_path=rel_path,
            out_dir=out_dir,
        )
        downloaded[kind] = str(local)
        if kind == "run.error.json":
            run_error = _read_json_file(local)

    if missing:
        raise E2EError(
            event_code="SSE2E_ARTIFACTS_MISSING",
            message=f"missing required artifacts: {missing}",
            details={"missing": missing, "downloaded": downloaded},
        )

    return downloaded, run_error


def verify_artifacts_and_download(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    out_dir: Path,
    status: str,
) -> tuple[dict[str, str], str | None]:
    artifacts_payload = fetch_artifacts_index(
        httpx=httpx,
        base_url=base_url,
        headers=headers,
        job_id=job_id,
    )
    write_text(out_dir / "artifacts_index.json", json_dumps(redact(artifacts_payload)))
    artifacts = extract_artifacts_list(artifacts_payload)
    required_kinds = required_kinds_for_status(status)
    downloaded, run_error = download_required_artifacts(
        httpx=httpx,
        base_url=base_url,
        headers=headers,
        job_id=job_id,
        out_dir=out_dir,
        artifacts=artifacts,
        required_kinds=required_kinds,
    )

    if not isinstance(run_error, dict):
        return downloaded, None
    error_code = str(run_error.get("error_code", ""))
    if error_code == "":
        return downloaded, None
    return downloaded, domain_guess_from_error_code(error_code)


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
    tenant_headers = {"X-SS-Tenant-ID": tenant_id}
    with httpx.Client(
        base_url=base_url,
        headers=tenant_headers,
        timeout=http_timeout_seconds,
    ) as client:
        check_health(client=client, ignore_unhealthy=ignore_unhealthy)
        job_id, token = redeem_task_code(
            client=client,
            task_code=task_code,
            requirement=requirement,
        )

    headers = {"Authorization": f"Bearer {token}", **tenant_headers}
    with httpx.Client(base_url=base_url, headers=headers, timeout=http_timeout_seconds) as authed:
        run_authed_journey(client=authed, job_id=job_id)

    final_job = poll_job(
        httpx=httpx,
        base_url=base_url,
        headers=headers,
        job_id=job_id,
        poll_interval_seconds=poll_interval_seconds,
        max_wait_seconds=max_wait_seconds,
    )
    status = str(final_job.get("status", ""))
    downloaded, failure_domain = verify_artifacts_and_download(
        httpx=httpx,
        base_url=base_url,
        headers=headers,
        job_id=job_id,
        out_dir=out_dir,
        status=status,
    )

    return {
        "task_code": task_code,
        "job_id": job_id,
        "status": status,
        "failure_domain_guess": failure_domain,
        "artifacts_downloaded": downloaded,
        "tenant_id": tenant_id,
        "final_job": redact(final_job),
    }
