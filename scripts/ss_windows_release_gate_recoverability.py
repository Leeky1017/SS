from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any
from urllib.parse import quote

from ss_ssh_e2e.errors import json_dumps, write_text
from ss_ssh_e2e.http_utils import http_json

DEFAULT_REMOTE_API_HOST = "127.0.0.1"
DEFAULT_REMOTE_API_PORT = 8000
DEFAULT_RESTART_READY_TIMEOUT_SECONDS = 60.0


def _record_json_evidence(
    *,
    out_dir: Path,
    filename: str,
    payload: Any,
    evidence: dict[str, str],
) -> None:
    path = out_dir / filename
    write_text(path, json_dumps(payload))
    evidence[filename] = str(path)


def _wait_api_ready(
    *,
    httpx: Any,
    base_url: str,
    timeout_seconds: float,
    tenant_headers: dict[str, str],
) -> dict[str, Any]:
    deadline = time.time() + timeout_seconds
    last: dict[str, Any] = {}
    with httpx.Client(base_url=base_url, headers=tenant_headers, timeout=10.0) as client:
        while time.time() < deadline:
            try:
                resp = client.get("/health/ready")
            except httpx.HTTPError as e:
                last = {"error_type": type(e).__name__, "message": str(e)}
                time.sleep(1.0)
                continue
            last = {"status_code": resp.status_code}
            if resp.status_code == 200:
                return {"ok": True, "last": last}
            time.sleep(1.0)
    return {"ok": False, "last": last}


def _redeem_task_code(
    *,
    httpx: Any,
    base_url: str,
    tenant_headers: dict[str, str],
    task_code: str,
) -> tuple[int, dict[str, Any]]:
    try:
        with httpx.Client(base_url=base_url, headers=tenant_headers, timeout=30.0) as client:
            resp = client.post(
                "/v1/task-codes/redeem",
                json={"task_code": task_code, "requirement": "recoverability check"},
            )
    except httpx.HTTPError as e:
        return 0, {"error_type": type(e).__name__, "message": str(e)}
    return resp.status_code, http_json(resp)


def _get_job(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
) -> tuple[int, dict[str, Any]]:
    try:
        with httpx.Client(base_url=base_url, headers=headers, timeout=60.0) as client:
            resp = client.get(f"/v1/jobs/{job_id}")
    except httpx.HTTPError as e:
        return 0, {"error_type": type(e).__name__, "message": str(e)}
    return resp.status_code, http_json(resp)


def _download_artifact(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    rel_path: str,
) -> tuple[int, bytes]:
    url_path = quote(rel_path, safe="/")
    try:
        with httpx.Client(base_url=base_url, headers=headers, timeout=60.0) as client:
            resp = client.get(f"/v1/jobs/{job_id}/artifacts/{url_path}")
    except httpx.HTTPError:
        return 0, b""
    return resp.status_code, resp.content


def _redeem_headers_for_recoverability(
    *,
    httpx: Any,
    base_url: str,
    tenant_headers: dict[str, str],
    task_code: str,
    expected_job_id: str,
    evidence: dict[str, str],
    out_dir: Path,
) -> tuple[dict[str, str] | None, str | None]:
    redeem_status, redeem_payload = _redeem_task_code(
        httpx=httpx, base_url=base_url, tenant_headers=tenant_headers, task_code=task_code
    )
    _record_json_evidence(out_dir=out_dir, filename="recoverability.redeem.json",
        payload=redeem_payload, evidence=evidence)
    if redeem_status != 200:
        return None, "redeem_failed"
    job_id = str(redeem_payload.get("job_id", ""))
    token = str(redeem_payload.get("token", ""))
    if job_id != expected_job_id or not token.startswith("ssv1."):
        return None, "redeem_payload_mismatch"
    return {"Authorization": f"Bearer {token}", **tenant_headers}, None


def _verify_job_terminal_status(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    expected_terminal_status: str,
    evidence: dict[str, str],
    out_dir: Path,
) -> str | None:
    status, payload = _get_job(httpx=httpx, base_url=base_url, headers=headers, job_id=job_id)
    _record_json_evidence(
        out_dir=out_dir,
        filename="recoverability.job.json",
        payload=payload,
        evidence=evidence,
    )
    if status != 200:
        return "job_get_failed"
    if str(payload.get("status", "")) != expected_terminal_status:
        return "job_status_mismatch"
    return None


def _download_plan_json(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    out_dir: Path,
    evidence: dict[str, str],
) -> tuple[str | None, str]:
    artifact_rel = "artifacts/plan.json"
    try:
        with httpx.Client(base_url=base_url, headers=headers, timeout=60.0) as client:
            idx_resp = client.get(f"/v1/jobs/{job_id}/artifacts")
        idx_status = idx_resp.status_code
        idx_payload = http_json(idx_resp)
    except httpx.HTTPError as e:
        idx_status = 0
        idx_payload = {"error_type": type(e).__name__, "message": str(e)}
    _record_json_evidence(out_dir=out_dir, filename="recoverability.artifacts_index.json",
        payload=idx_payload, evidence=evidence)
    if idx_status != 200:
        return "artifacts_index_failed", artifact_rel
    artifacts = idx_payload.get("artifacts", [])
    if not isinstance(artifacts, list):
        return "artifacts_index_bad_payload", artifact_rel
    if not any(
        isinstance(item, dict) and str(item.get("kind", "")) == "plan.json"
        for item in artifacts
    ):
        return "plan_missing_in_artifacts_index", artifact_rel
    art_status, art_bytes = _download_artifact(
        httpx=httpx, base_url=base_url, headers=headers, job_id=job_id, rel_path=artifact_rel
    )
    if art_status != 200:
        return "artifact_download_failed", artifact_rel
    artifact_path = out_dir / "recoverability.plan.json"
    artifact_path.write_bytes(art_bytes)
    evidence["recoverability.plan.json"] = str(artifact_path)
    try:
        json.loads(artifact_path.read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError):
        return "plan_json_invalid", artifact_rel
    return None, artifact_rel


def _recoverability_ready_error(
    *,
    httpx: Any,
    base_url: str,
    tenant_headers: dict[str, str],
    out_dir: Path,
    evidence: dict[str, str],
) -> str | None:
    ready = _wait_api_ready(
        httpx=httpx,
        base_url=base_url,
        timeout_seconds=DEFAULT_RESTART_READY_TIMEOUT_SECONDS,
        tenant_headers=tenant_headers,
    )
    _record_json_evidence(
        out_dir=out_dir, filename="recoverability.health.json", payload=ready, evidence=evidence
    )
    if not bool(ready.get("ok")):
        return "api_not_ready"
    return None


def _recoverability_steps(
    *,
    httpx: Any,
    base_url: str,
    tenant_headers: dict[str, str],
    task_code: str,
    expected_job_id: str,
    expected_terminal_status: str,
    out_dir: Path,
    evidence: dict[str, str],
) -> tuple[bool, str | None, str | None]:
    ready_error = _recoverability_ready_error(
        httpx=httpx, base_url=base_url, tenant_headers=tenant_headers, out_dir=out_dir,
        evidence=evidence,
    )
    if ready_error is not None:
        return False, ready_error, None
    headers, redeem_error = _redeem_headers_for_recoverability(
        httpx=httpx, base_url=base_url, tenant_headers=tenant_headers, task_code=task_code,
        expected_job_id=expected_job_id, evidence=evidence, out_dir=out_dir,
    )
    if redeem_error is not None or headers is None:
        return False, redeem_error, None
    job_error = _verify_job_terminal_status(
        httpx=httpx, base_url=base_url, headers=headers, job_id=expected_job_id,
        expected_terminal_status=expected_terminal_status, evidence=evidence, out_dir=out_dir,
    )
    if job_error is not None:
        return False, job_error, None
    artifact_error, artifact_rel = _download_plan_json(
        httpx=httpx, base_url=base_url, headers=headers, job_id=expected_job_id, out_dir=out_dir,
        evidence=evidence,
    )
    if artifact_error is not None:
        return False, artifact_error, artifact_rel
    return True, None, artifact_rel


def recoverability_check(
    *,
    out_dir: Path,
    user: str,
    host: str,
    port: int,
    identity_file: str,
    tenant_id: str,
    task_code: str,
    expected_job_id: str,
    expected_terminal_status: str,
) -> dict[str, Any]:
    from ss_ssh_e2e.flow import require_httpx
    from ss_ssh_e2e.tunnel import pick_free_port, ssh_tunnel

    httpx = require_httpx()
    local_port = pick_free_port()
    base_url = f"http://127.0.0.1:{local_port}"
    tenant_headers = {"X-SS-Tenant-ID": tenant_id}
    evidence: dict[str, str] = {}

    with ssh_tunnel(
        user=user, host=host, port=port, identity_file=identity_file, local_port=local_port,
        remote_host=DEFAULT_REMOTE_API_HOST, remote_port=DEFAULT_REMOTE_API_PORT,
        ready_timeout_seconds=10.0,
    ):
        ok, error, artifact_rel = _recoverability_steps(
            httpx=httpx, base_url=base_url, tenant_headers=tenant_headers, task_code=task_code,
            expected_job_id=expected_job_id, expected_terminal_status=expected_terminal_status,
            out_dir=out_dir, evidence=evidence,
        )
        if not ok:
            return {"attempted": True, "ok": False, "evidence": evidence, "error": error}

    return {
        "attempted": True,
        "ok": True,
        "evidence": evidence,
        "job_id": expected_job_id,
        "status_before": expected_terminal_status,
        "status_after": expected_terminal_status,
        "artifact_rel_path": artifact_rel,
    }
