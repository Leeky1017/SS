from __future__ import annotations

from fastapi.testclient import TestClient

from tests.v1_redeem import redeem_job_sync


def test_non_v1_business_paths_return_404(journey_test_client: TestClient) -> None:
    response = journey_test_client.get("/jobs")
    assert response.status_code == 404

    response = journey_test_client.post("/jobs", json={"requirement": "ignored"})
    assert response.status_code == 404

    response = journey_test_client.get("/jobs/anything")
    assert response.status_code == 404


def test_ops_endpoints_remain_reachable(journey_test_client: TestClient) -> None:
    response = journey_test_client.get("/health/live")
    assert response.status_code == 200

    response = journey_test_client.get("/metrics")
    assert response.status_code == 200


def test_v1_business_paths_remain_routable(journey_test_client: TestClient) -> None:
    job_id, token = redeem_job_sync(
        client=journey_test_client,
        task_code="tc_journey_routing_01",
        requirement="test requirement",
    )
    assert job_id.startswith("job_tc_")
    assert token.startswith("ssv1.")
