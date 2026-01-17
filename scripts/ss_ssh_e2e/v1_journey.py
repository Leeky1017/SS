from __future__ import annotations

from typing import Any

from ss_ssh_e2e.errors import E2EError, redact
from ss_ssh_e2e.http_trace import HttpTrace
from ss_ssh_e2e.http_utils import assert_status, http_json

PLAN_JSON_REL_PATH = "artifacts/plan.json"


def _as_dict(value: Any) -> dict[str, Any]:
    return value if isinstance(value, dict) else {}


def check_health(*, client: Any, ignore_unhealthy: bool, trace: HttpTrace) -> None:
    ready = client.get("/health/ready")
    trace.add(method="GET", path="/health/ready", status_code=ready.status_code)
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


def redeem_task_code(
    *,
    client: Any,
    task_code: str,
    requirement: str,
    trace: HttpTrace,
) -> tuple[str, str, dict[str, Any]]:
    redeem = client.post(
        "/v1/task-codes/redeem",
        json={"task_code": task_code, "requirement": requirement},
    )
    payload = http_json(redeem)
    trace.add(
        method="POST",
        path="/v1/task-codes/redeem",
        status_code=redeem.status_code,
        body=payload,
    )
    assert_status(redeem, expected=200, context="redeem task code")
    data = _as_dict(payload)
    job_id = str(data.get("job_id", ""))
    token = str(data.get("token", ""))
    if not job_id.startswith("job_") or not token.startswith("ssv1."):
        raise E2EError(
            event_code="SSE2E_REDEEM_BAD_PAYLOAD",
            message="unexpected redeem payload",
            details={"payload": redact(data)},
        )
    return job_id, token, data


def upload_inputs(*, client: Any, job_id: str, trace: HttpTrace) -> None:
    csv_bytes = b"id,y,x\n1,2,3\n2,4,6\n"
    path = f"/v1/jobs/{job_id}/inputs/upload"
    upload = client.post(
        path,
        files={"file": ("primary.csv", csv_bytes, "text/csv")},
    )
    trace.add(method="POST", path=path, status_code=upload.status_code)
    assert_status(upload, expected=200, context="inputs upload")


def preview_inputs(*, client: Any, job_id: str, trace: HttpTrace) -> None:
    path = f"/v1/jobs/{job_id}/inputs/preview"
    preview = client.get(path)
    trace.add(method="GET", path=path, status_code=preview.status_code)
    assert_status(preview, expected=200, context="inputs preview")


def draft_preview(*, client: Any, job_id: str, trace: HttpTrace) -> None:
    path = f"/v1/jobs/{job_id}/draft/preview"
    draft = client.get(path)
    trace.add(method="GET", path=path, status_code=draft.status_code)
    assert_status(draft, expected=200, context="draft preview (LLM)")


def draft_patch(*, client: Any, job_id: str, trace: HttpTrace) -> None:
    path = f"/v1/jobs/{job_id}/draft/patch"
    patched = client.post(
        path,
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    trace.add(method="POST", path=path, status_code=patched.status_code)
    assert_status(patched, expected=200, context="draft patch")


def freeze_plan_expect_missing_required(
    *,
    client: Any,
    job_id: str,
    trace: HttpTrace,
) -> dict[str, Any]:
    path = f"/v1/jobs/{job_id}/plan/freeze"
    blocked = client.post(path, json={})
    payload = http_json(blocked)
    trace.add(method="POST", path=path, status_code=blocked.status_code, body=payload)
    assert_status(blocked, expected=400, context="plan freeze blocked")
    data = _as_dict(payload)

    if str(data.get("error_code", "")) != "PLAN_FREEZE_MISSING_REQUIRED":
        raise E2EError(
            event_code="SSE2E_AUDIT_UNEXPECTED_ERROR_CODE",
            message="plan freeze blocked but error_code mismatch",
            details={"payload": redact(data)},
        )
    missing_fields = data.get("missing_fields", [])
    if not isinstance(missing_fields, list):
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_ERROR_PAYLOAD",
            message="plan freeze missing_fields is not a list",
            details={"payload": redact(data)},
        )
    required = {"stage1_questions.analysis_goal"}
    actual = {str(x) for x in missing_fields}
    if not required.issubset(actual):
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_ERROR_PAYLOAD",
            message="plan freeze missing_fields missing expected entries",
            details={"required": sorted(required), "actual": sorted(actual)},
        )
    if not isinstance(data.get("next_actions"), list):
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_ERROR_PAYLOAD",
            message="plan freeze next_actions is not a list",
            details={"payload": redact(data)},
        )
    return data


def freeze_plan(*, client: Any, job_id: str, trace: HttpTrace) -> dict[str, Any]:
    path = f"/v1/jobs/{job_id}/plan/freeze"
    frozen = client.post(path, json={"answers": {"analysis_goal": "descriptive"}})
    payload = http_json(frozen)
    trace.add(method="POST", path=path, status_code=frozen.status_code, body=payload)
    assert_status(frozen, expected=200, context="plan freeze")
    data = _as_dict(payload)
    plan = data.get("plan", {})
    if not isinstance(plan, dict):
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_PLAN_PAYLOAD",
            message="plan freeze payload missing plan",
            details={"payload": redact(data)},
        )
    rel_path = str(plan.get("rel_path", ""))
    if rel_path != PLAN_JSON_REL_PATH:
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_PLAN_PAYLOAD",
            message="plan freeze plan.rel_path mismatch",
            details={"expected": PLAN_JSON_REL_PATH, "actual": rel_path},
        )
    if str(plan.get("plan_id", "")) == "":
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_PLAN_PAYLOAD",
            message="plan freeze plan_id missing",
            details={"payload": redact(data)},
        )
    return data


def get_plan(
    *,
    client: Any,
    job_id: str,
    expected_plan_id: str,
    trace: HttpTrace,
) -> dict[str, Any]:
    path = f"/v1/jobs/{job_id}/plan"
    got = client.get(path)
    payload = http_json(got)
    trace.add(method="GET", path=path, status_code=got.status_code, body=payload)
    assert_status(got, expected=200, context="get plan")
    data = _as_dict(payload)
    plan = data.get("plan", {})
    if not isinstance(plan, dict):
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_PLAN_PAYLOAD",
            message="get plan payload missing plan",
            details={"payload": redact(data)},
        )
    plan_id = str(plan.get("plan_id", ""))
    if plan_id != expected_plan_id:
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_PLAN_PAYLOAD",
            message="get plan plan_id mismatch",
            details={"expected": expected_plan_id, "actual": plan_id},
        )
    return data


def run_job(*, client: Any, job_id: str, trace: HttpTrace) -> dict[str, Any]:
    path = f"/v1/jobs/{job_id}/run"
    run = client.post(path)
    payload = http_json(run)
    trace.add(method="POST", path=path, status_code=run.status_code, body=payload)
    assert_status(run, expected=200, context="run")
    data = _as_dict(payload)
    if str(data.get("job_id", "")) != job_id:
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_RUN_PAYLOAD",
            message="run response job_id mismatch",
            details={"payload": redact(data)},
        )
    if str(data.get("status", "")) == "":
        raise E2EError(
            event_code="SSE2E_AUDIT_BAD_RUN_PAYLOAD",
            message="run response missing status",
            details={"payload": redact(data)},
        )
    return data


def run_authed_journey(*, client: Any, job_id: str, trace: HttpTrace) -> dict[str, Any]:
    upload_inputs(client=client, job_id=job_id, trace=trace)
    preview_inputs(client=client, job_id=job_id, trace=trace)
    draft_preview(client=client, job_id=job_id, trace=trace)

    blocked = freeze_plan_expect_missing_required(client=client, job_id=job_id, trace=trace)
    draft_patch(client=client, job_id=job_id, trace=trace)

    frozen = freeze_plan(client=client, job_id=job_id, trace=trace)
    plan = _as_dict(frozen.get("plan"))
    plan_id = str(plan.get("plan_id", ""))
    got = get_plan(client=client, job_id=job_id, expected_plan_id=plan_id, trace=trace)
    triggered = run_job(client=client, job_id=job_id, trace=trace)

    return {
        "plan_freeze_blocked": redact(blocked),
        "plan_freeze": redact(frozen),
        "plan_get": redact(got),
        "run": redact(triggered),
    }


def redeem_and_build_headers(
    *,
    httpx: Any,
    base_url: str,
    tenant_id: str,
    task_code: str,
    requirement: str,
    ignore_unhealthy: bool,
    http_timeout_seconds: float,
    trace: HttpTrace,
) -> tuple[str, dict[str, str], dict[str, Any]]:
    tenant_headers = {"X-SS-Tenant-ID": tenant_id}
    with httpx.Client(
        base_url=base_url,
        headers=tenant_headers,
        timeout=http_timeout_seconds,
    ) as client:
        check_health(client=client, ignore_unhealthy=ignore_unhealthy, trace=trace)
        job_id, token, redeem_payload = redeem_task_code(
            client=client,
            task_code=task_code,
            requirement=requirement,
            trace=trace,
        )
    headers = {"Authorization": f"Bearer {token}", **tenant_headers}
    return job_id, headers, redeem_payload
