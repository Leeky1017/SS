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
from ss_ssh_e2e.http_trace import HttpTrace
from ss_ssh_e2e.http_utils import assert_status


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
    trace: HttpTrace | None,
) -> Path:
    safe_rel = safe_posix_rel_path(rel_path)
    url_path = quote(rel_path, safe="/")
    with httpx.Client(base_url=base_url, headers=headers, timeout=120.0) as client:
        resp = client.get(f"/v1/jobs/{job_id}/artifacts/{url_path}")
    if trace is not None:
        trace.add(
            method="GET",
            path=f"/v1/jobs/{job_id}/artifacts/{url_path}",
            status_code=resp.status_code,
            extra={"rel_path": rel_path},
        )
    assert_status(resp, expected=200, context=f"download artifact {rel_path}")
    local = out_dir / "artifacts" / Path(str(safe_rel))
    write_bytes(local, resp.content)
    return local


def fetch_artifacts_index(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    trace: HttpTrace | None,
) -> dict[str, Any]:
    with httpx.Client(base_url=base_url, headers=headers, timeout=120.0) as authed:
        artifacts_resp = authed.get(f"/v1/jobs/{job_id}/artifacts")
    if trace is not None:
        trace.add(
            method="GET",
            path=f"/v1/jobs/{job_id}/artifacts",
            status_code=artifacts_resp.status_code,
        )
    assert_status(artifacts_resp, expected=200, context="artifacts index")
    return artifacts_resp.json()


def extract_artifacts_list(payload: dict[str, Any]) -> list[dict[str, Any]]:
    artifacts = payload.get("artifacts", [])
    if not isinstance(artifacts, list):
        raise E2EError(
            event_code="SSE2E_ARTIFACTS_BAD_PAYLOAD",
            message="artifacts payload missing artifacts list",
        )
    return [item for item in artifacts if isinstance(item, dict)]


def required_kinds_for_status(status: str) -> list[str]:
    required = ["plan.json", "llm.meta", "stata.log", "run.meta.json"]
    if status == "failed":
        return ["run.error.json", *required]
    return required


def _read_json_file(path: Path) -> dict[str, Any] | None:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None


def _require_json_dict(*, path: Path, label: str) -> dict[str, Any]:
    payload = _read_json_file(path)
    if isinstance(payload, dict):
        return payload
    raise E2EError(
        event_code="SSE2E_AUDIT_JSON_INVALID",
        message=f"{label} is not valid JSON object",
        details={"path": str(path)},
    )


def _assert_llm_meta_model(*, llm_meta: dict[str, Any], expected_model: str) -> None:
    model = str(llm_meta.get("model", ""))
    if model == expected_model:
        return
    raise E2EError(
        event_code="SSE2E_AUDIT_LLM_MODEL_MISMATCH",
        message="llm.meta model mismatch",
        details={"expected": expected_model, "actual": model, "llm_meta": redact(llm_meta)},
    )


def _assert_run_meta(*, run_meta: dict[str, Any], job_id: str, status: str) -> None:
    if str(run_meta.get("job_id", "")) != job_id:
        raise E2EError(
            event_code="SSE2E_AUDIT_RUN_META_MISMATCH",
            message="run.meta.json job_id mismatch",
            details={"expected": job_id, "actual": run_meta.get("job_id")},
        )
    command = run_meta.get("command")
    if not isinstance(command, list) or not command or not all(isinstance(x, str) for x in command):
        raise E2EError(
            event_code="SSE2E_AUDIT_RUN_META_INVALID",
            message="run.meta.json missing command list",
            details={"run_meta": redact(run_meta)},
        )
    if not isinstance(run_meta.get("duration_ms"), int):
        raise E2EError(
            event_code="SSE2E_AUDIT_RUN_META_INVALID",
            message="run.meta.json missing duration_ms",
            details={"run_meta": redact(run_meta)},
        )
    exit_code = run_meta.get("exit_code")
    if not isinstance(exit_code, int) and exit_code is not None:
        raise E2EError(
            event_code="SSE2E_AUDIT_RUN_META_INVALID",
            message="run.meta.json exit_code has unexpected type",
            details={"exit_code": exit_code},
        )
    ok = run_meta.get("ok")
    if status == "succeeded":
        if ok is not True or exit_code != 0:
            raise E2EError(
                event_code="SSE2E_AUDIT_RUN_META_INCONSISTENT",
                message="succeeded job has non-ok run meta",
                details={"run_meta": redact(run_meta)},
            )


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


def download_required_artifacts(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    out_dir: Path,
    artifacts: list[dict[str, Any]],
    required_kinds: list[str],
    trace: HttpTrace | None,
) -> tuple[dict[str, str], dict[str, str], dict[str, Any] | None]:
    downloaded: dict[str, str] = {}
    rel_paths: dict[str, str] = {}
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
            trace=trace,
        )
        downloaded[kind] = str(local)
        rel_paths[kind] = rel_path
        if kind == "run.error.json":
            run_error = _read_json_file(local)

    if missing:
        raise E2EError(
            event_code="SSE2E_ARTIFACTS_MISSING",
            message=f"missing required artifacts: {missing}",
            details={"missing": missing, "downloaded": downloaded},
        )

    return downloaded, rel_paths, run_error


def verify_audit_artifacts(
    *,
    httpx: Any,
    base_url: str,
    headers: dict[str, str],
    job_id: str,
    out_dir: Path,
    status: str,
    expected_llm_model: str,
    trace: HttpTrace | None,
) -> dict[str, Any]:
    artifacts_payload = fetch_artifacts_index(
        httpx=httpx, base_url=base_url, headers=headers, job_id=job_id, trace=trace
    )
    write_text(out_dir / "artifacts_index.json", json_dumps(redact(artifacts_payload)))
    downloaded, rel_paths, run_error = download_required_artifacts(
        httpx=httpx, base_url=base_url, headers=headers, job_id=job_id, out_dir=out_dir,
        artifacts=extract_artifacts_list(artifacts_payload),
        required_kinds=required_kinds_for_status(status),
        trace=trace,
    )
    plan = _require_json_dict(path=Path(downloaded["plan.json"]), label="plan.json")
    llm_meta = _require_json_dict(path=Path(downloaded["llm.meta"]), label="llm.meta")
    run_meta = _require_json_dict(path=Path(downloaded["run.meta.json"]), label="run.meta.json")
    _assert_llm_meta_model(llm_meta=llm_meta, expected_model=expected_llm_model)
    _assert_run_meta(run_meta=run_meta, job_id=job_id, status=status)
    stata_log = Path(downloaded["stata.log"])
    stata_log_bytes = stata_log.stat().st_size if stata_log.is_file() else 0
    if stata_log_bytes <= 0:
        raise E2EError(event_code="SSE2E_AUDIT_STATA_LOG_EMPTY",
            message="stata.log missing or empty", details={"path": str(stata_log)})
    failure_domain = (
        domain_guess_from_error_code(str(run_error.get("error_code", "")))
        if isinstance(run_error, dict) and str(run_error.get("error_code", "")) != ""
        else None
    )
    audit_evidence = {
        "expected_llm_model": expected_llm_model,
        "plan": redact(plan),
        "llm_meta": redact(llm_meta),
        "run_meta": redact(run_meta),
        "stata_log_bytes": stata_log_bytes,
    }
    return {
        "artifacts_downloaded": downloaded,
        "artifacts_rel_paths": rel_paths,
        "audit_evidence": audit_evidence,
        "failure_domain_guess": failure_domain,
    }
