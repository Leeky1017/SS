from __future__ import annotations

import os
import time
from pathlib import Path

import pytest
from fastapi.testclient import TestClient

from src.domain.models import ArtifactKind, ArtifactRef
from src.utils.job_workspace import resolve_job_dir
from tests.stress._metrics import env_float, env_int, take_resource_snapshot

pytestmark = pytest.mark.stress


def _make_wide_csv_header(columns: int) -> str:
    return ",".join(f"c{i}" for i in range(columns)) + "\n"


def _create_job(*, client: TestClient, requirement: str) -> str:
    response = client.post(
        "/v1/task-codes/redeem",
        json={"task_code": f"tc_large_{int(time.time() * 1000)}", "requirement": requirement},
    )
    assert response.status_code == 200
    client.headers.update({"Authorization": f"Bearer {response.json()['token']}"})
    return str(response.json()["job_id"])


def _preview(*, client: TestClient, job_id: str) -> dict[str, object]:
    response = client.get(f"/v1/jobs/{job_id}/draft/preview")
    assert response.status_code == 200
    payload: dict[str, object] = response.json()
    return payload


def test_large_input_100k_chars_preview_bounded_latency(stress_client: TestClient) -> None:
    max_seconds = env_float("SS_STRESS_LARGE_INPUT_MAX_SECONDS", 2.0)
    requirement = "x" * 100_000

    job_id = _create_job(client=stress_client, requirement=requirement)
    start = time.monotonic()
    payload = _preview(client=stress_client, job_id=job_id)
    elapsed = time.monotonic() - start

    assert payload["job_id"] == job_id
    assert len(str(payload["draft_text"])) >= 100_000
    assert elapsed < max_seconds


def test_large_dataset_boundaries_1gb_csv_and_500_cols_are_indexable(
    stress_client: TestClient,
    stress_store,
    stress_jobs_dir: Path,
) -> None:
    max_rss_mb = env_float("SS_STRESS_MAX_RSS_MB", 500.0)
    max_open_fds = env_int("SS_STRESS_MAX_OPEN_FDS", 1024)

    job_id = _create_job(client=stress_client, requirement="boundary-dataset")
    job_dir = resolve_job_dir(jobs_dir=stress_jobs_dir, job_id=job_id)
    assert job_dir is not None
    artifacts_dir = job_dir / "artifacts" / "data"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    large_csv_rel = "artifacts/data/large_1gb.csv"
    large_csv_path = job_dir / large_csv_rel
    with open(large_csv_path, "wb") as f:
        f.truncate(1_073_741_824)

    wide_csv_rel = "artifacts/data/wide_500cols.csv"
    wide_csv_path = job_dir / wide_csv_rel
    wide_csv_path.write_text(_make_wide_csv_header(500), encoding="utf-8")

    job = stress_store.load(job_id)
    job.artifacts_index.extend(
        [
            ArtifactRef(kind=ArtifactKind.STATA_EXPORT_TABLE, rel_path=large_csv_rel),
            ArtifactRef(kind=ArtifactKind.STATA_EXPORT_TABLE, rel_path=wide_csv_rel),
        ]
    )
    stress_store.save(job)

    response = stress_client.get(f"/v1/jobs/{job_id}/artifacts")
    assert response.status_code == 200
    payload = response.json()
    rel_paths = {a["rel_path"] for a in payload["artifacts"]}
    assert large_csv_rel in rel_paths
    assert wide_csv_rel in rel_paths

    snapshot = take_resource_snapshot()
    if snapshot.rss_mb is not None:
        assert snapshot.rss_mb < max_rss_mb
    if snapshot.open_fds is not None:
        assert snapshot.open_fds < max_open_fds

    if os.name == "posix":
        assert large_csv_path.stat().st_size == 1_073_741_824
