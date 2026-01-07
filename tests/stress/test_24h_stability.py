from __future__ import annotations

import time
import uuid
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from tests.stress._metrics import (
    LatencyRecorder,
    env_float,
    env_int,
    take_resource_snapshot,
    write_json_report,
)

pytestmark = pytest.mark.stress


def _create_job(*, client: TestClient, recorder: LatencyRecorder, requirement: str) -> str:
    start = time.monotonic()
    response = client.post("/v1/jobs", json={"requirement": requirement})
    recorder.record(duration_ms=(time.monotonic() - start) * 1000.0, ok=response.status_code == 200)
    assert response.status_code == 200
    return str(response.json()["job_id"])


def _preview_job(*, client: TestClient, recorder: LatencyRecorder, job_id: str) -> None:
    start = time.monotonic()
    response = client.get(f"/v1/jobs/{job_id}/draft/preview")
    recorder.record(duration_ms=(time.monotonic() - start) * 1000.0, ok=response.status_code == 200)
    assert response.status_code == 200


def _confirm_job(*, client: TestClient, recorder: LatencyRecorder, job_id: str) -> None:
    start = time.monotonic()
    response = client.post(f"/v1/jobs/{job_id}/confirm", json={"confirmed": True})
    recorder.record(duration_ms=(time.monotonic() - start) * 1000.0, ok=response.status_code == 200)
    assert response.status_code == 200


def _run_one_iteration(*, client: TestClient, recorder: LatencyRecorder, requirement: str) -> None:
    job_id = _create_job(client=client, recorder=recorder, requirement=requirement)
    _preview_job(client=client, recorder=recorder, job_id=job_id)
    _confirm_job(client=client, recorder=recorder, job_id=job_id)


def _max_or_none(values: list[float | int | None]) -> float | int | None:
    known = [v for v in values if v is not None]
    if not known:
        return None
    return max(known)


def test_stability_run_loop_24h_bounds_resources(stress_client: TestClient, tmp_path: Path) -> None:
    duration_seconds = env_int("SS_STRESS_DURATION_SECONDS", 60)
    sample_every_seconds = env_int("SS_STRESS_SAMPLE_EVERY_SECONDS", 10)
    sleep_between_iterations = env_float("SS_STRESS_ITERATION_SLEEP_SECONDS", 0.05)

    max_rss_mb = env_float("SS_STRESS_MAX_RSS_MB", 500.0)
    max_open_fds = env_int("SS_STRESS_MAX_OPEN_FDS", 1024)

    recorder = LatencyRecorder()
    snapshots = [take_resource_snapshot()]
    started_at = time.monotonic()
    next_sample_at = started_at + float(sample_every_seconds)

    while time.monotonic() - started_at < float(duration_seconds):
        requirement = f"stability-{uuid.uuid4()}"
        _run_one_iteration(client=stress_client, recorder=recorder, requirement=requirement)
        if sleep_between_iterations > 0:
            time.sleep(sleep_between_iterations)

        now = time.monotonic()
        if now >= next_sample_at:
            snapshots.append(take_resource_snapshot())
            next_sample_at = now + float(sample_every_seconds)

    snapshots.append(take_resource_snapshot())
    summary = recorder.summary()
    report = {
        "duration_seconds": duration_seconds,
        "requests": {
            "total": summary.total,
            "ok": summary.ok,
            "errors": summary.errors,
            "error_rate": summary.error_rate,
            "p50_ms": summary.p50_ms,
            "p90_ms": summary.p90_ms,
            "p99_ms": summary.p99_ms,
        },
        "resources": [s.__dict__ for s in snapshots],
    }
    write_json_report(path=tmp_path / "stress" / "stability_report.json", payload=report)

    max_rss = _max_or_none([s.rss_mb for s in snapshots])
    max_fds = _max_or_none([s.open_fds for s in snapshots])
    if max_rss is not None:
        assert float(max_rss) < max_rss_mb
    if max_fds is not None:
        assert int(max_fds) < max_open_fds
