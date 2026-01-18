from __future__ import annotations

from fastapi.testclient import TestClient


def test_tokenized_step3_journey_with_patch_and_confirm_succeeds(
    journey_test_client: TestClient,
) -> None:
    # redeem → token
    redeemed = journey_test_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_demo_01", "requirement": "estimate the effect of x on y"},
    )
    assert redeemed.status_code == 200
    job_id = redeemed.json()["job_id"]
    token = redeemed.json()["token"]

    # missing-token / wrong-token rejects (stable error_code)
    missing = journey_test_client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert missing.status_code == 401
    assert missing.json()["error_code"] == "AUTH_BEARER_TOKEN_MISSING"

    redeemed_other = journey_test_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_demo_02", "requirement": ""},
    )
    assert redeemed_other.status_code == 200
    wrong_token = redeemed_other.json()["token"]

    forbidden = journey_test_client.get(
        f"/v1/jobs/{job_id}/draft/preview",
        headers={"Authorization": f"Bearer {wrong_token}"},
    )
    assert forbidden.status_code == 403
    assert forbidden.json()["error_code"] == "AUTH_TOKEN_FORBIDDEN"

    headers = {"Authorization": f"Bearer {token}"}

    # preview pending before upload
    pending = journey_test_client.get(f"/v1/jobs/{job_id}/draft/preview", headers=headers)
    assert pending.status_code == 202
    pending_payload = pending.json()
    assert pending_payload["status"] == "pending"
    assert pending_payload["retry_after_seconds"] > 0
    assert isinstance(pending_payload["retry_until"], str)

    # upload
    uploaded = journey_test_client.post(
        f"/v1/jobs/{job_id}/inputs/upload",
        headers=headers,
        files={"file": ("data.csv", b"y,x\n1,2\n2,3\n", "text/csv")},
    )
    assert uploaded.status_code == 200

    # preview → patch → confirm
    preview = journey_test_client.get(f"/v1/jobs/{job_id}/draft/preview", headers=headers)
    assert preview.status_code == 200
    preview_payload = preview.json()
    assert preview_payload["draft_id"] != ""
    assert "decision" in preview_payload
    assert "risk_score" in preview_payload
    assert isinstance(preview_payload["data_quality_warnings"], list)
    assert isinstance(preview_payload["stage1_questions"], list)
    assert isinstance(preview_payload["open_unknowns"], list)
    assert len(preview_payload["stage1_questions"]) > 0
    first_question = preview_payload["stage1_questions"][0]
    assert isinstance(first_question, dict)
    options = first_question.get("options")
    assert isinstance(options, list)
    assert len(options) > 0
    assert all(isinstance(opt, dict) for opt in options)
    assert all(
        isinstance(opt.get("option_id"), str)
        and isinstance(opt.get("label"), str)
        and "value" in opt
        for opt in options
    )

    job = journey_test_client.get(f"/v1/jobs/{job_id}", headers=headers)
    assert job.status_code == 200
    assert job.json()["selected_template_id"] not in {None, "", "stub_descriptive_v1"}

    artifacts = journey_test_client.get(f"/v1/jobs/{job_id}/artifacts", headers=headers)
    assert artifacts.status_code == 200
    kinds = {item["kind"] for item in artifacts.json()["artifacts"]}
    assert "do_template.selection.stage1" in kinds
    assert "do_template.selection.candidates" in kinds
    assert "do_template.selection.stage2" in kinds

    blocked = journey_test_client.post(
        f"/v1/jobs/{job_id}/confirm",
        headers=headers,
        json={
            "confirmed": True,
            "answers": {},
            "expert_suggestions_feedback": {},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert blocked.status_code == 400
    assert blocked.json()["error_code"] == "DRAFT_CONFIRM_BLOCKED"

    patched = journey_test_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        headers=headers,
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200
    patched_payload = patched.json()
    assert "outcome_var" in patched_payload["patched_fields"]
    assert "treatment_var" in patched_payload["patched_fields"]
    assert patched_payload["remaining_unknowns_count"] == 0

    confirmed = journey_test_client.post(
        f"/v1/jobs/{job_id}/confirm",
        headers=headers,
        json={
            "confirmed": True,
            "answers": {"analysis_goal": "descriptive"},
            "expert_suggestions_feedback": {"analysis_goal": "ok"},
            "variable_corrections": {},
            "default_overrides": {},
        },
    )
    assert confirmed.status_code == 200
    confirmed_payload = confirmed.json()
    assert confirmed_payload["job_id"] == job_id
    assert confirmed_payload["status"] == "queued"
    assert confirmed_payload["message"] != ""
    assert confirmed_payload["scheduled_at"] is not None


def test_tokenized_plan_freeze_when_missing_inputs_returns_structured_error(
    journey_test_client: TestClient,
) -> None:
    redeemed = journey_test_client.post(
        "/v1/task-codes/redeem",
        json={"task_code": "tc_demo_01", "requirement": "estimate the effect of x on y"},
    )
    assert redeemed.status_code == 200
    job_id = redeemed.json()["job_id"]
    token = redeemed.json()["token"]
    headers = {"Authorization": f"Bearer {token}"}

    uploaded = journey_test_client.post(
        f"/v1/jobs/{job_id}/inputs/upload",
        headers=headers,
        files={"file": ("data.csv", b"y,x\n1,2\n2,3\n", "text/csv")},
    )
    assert uploaded.status_code == 200

    preview = journey_test_client.get(f"/v1/jobs/{job_id}/draft/preview", headers=headers)
    assert preview.status_code == 200

    blocked = journey_test_client.post(f"/v1/jobs/{job_id}/plan/freeze", headers=headers, json={})
    assert blocked.status_code == 400
    payload = blocked.json()
    assert payload["error_code"] == "PLAN_FREEZE_MISSING_REQUIRED"
    assert "stage1_questions.analysis_goal" in payload.get("missing_fields", [])
    assert "open_unknowns.outcome_var" in payload.get("missing_fields", [])
    assert "open_unknowns.treatment_var" in payload.get("missing_fields", [])
    assert isinstance(payload.get("next_actions"), list)
    assert isinstance(payload.get("missing_fields_detail"), list)
    assert isinstance(payload.get("missing_params_detail"), list)
    assert isinstance(payload.get("action"), str)
    assert any(
        item.get("field") == "stage1_questions.analysis_goal"
        for item in payload.get("missing_fields_detail", [])
    )
    assert any(
        item.get("field") == "open_unknowns.outcome_var"
        for item in payload.get("missing_fields_detail", [])
    )

    patched = journey_test_client.post(
        f"/v1/jobs/{job_id}/draft/patch",
        headers=headers,
        json={"field_updates": {"outcome_var": "y", "treatment_var": "x", "controls": []}},
    )
    assert patched.status_code == 200

    frozen = journey_test_client.post(
        f"/v1/jobs/{job_id}/plan/freeze",
        headers=headers,
        json={"answers": {"analysis_goal": "descriptive"}},
    )
    assert frozen.status_code == 200
    assert frozen.json()["plan"]["rel_path"] == "artifacts/plan.json"
