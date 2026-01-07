from __future__ import annotations

import random
import threading
import time
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient

from tests.stress._metrics import (
    LatencyRecorder,
    env_float,
    env_int,
    take_resource_snapshot,
    write_json_report,
)

pytestmark = pytest.mark.stress


def _recorded_get(*, client: TestClient, recorder: LatencyRecorder, url: str) -> object:
    start = time.monotonic()
    response = client.get(url)
    recorder.record(duration_ms=(time.monotonic() - start) * 1000.0, ok=response.status_code < 400)
    return response


def _recorded_post(
    *,
    client: TestClient,
    recorder: LatencyRecorder,
    url: str,
    json_payload: dict[str, object],
) -> object:
    start = time.monotonic()
    response = client.post(url, json=json_payload)
    recorder.record(duration_ms=(time.monotonic() - start) * 1000.0, ok=response.status_code < 400)
    return response


def _create_job(*, app: FastAPI, recorder: LatencyRecorder) -> str:
    with TestClient(app) as client:
        requirement = f"stress-{uuid.uuid4()}"
        response = _recorded_post(
            client=client,
            recorder=recorder,
            url="/v1/jobs",
            json_payload={"requirement": requirement},
        )
        return str(response.json()["job_id"])


def _preview_job(*, app: FastAPI, recorder: LatencyRecorder, job_id: str) -> None:
    with TestClient(app) as client:
        _recorded_get(client=client, recorder=recorder, url=f"/v1/jobs/{job_id}/draft/preview")


def _confirm_job(*, app: FastAPI, recorder: LatencyRecorder, job_id: str) -> None:
    with TestClient(app) as client:
        _recorded_post(
            client=client,
            recorder=recorder,
            url=f"/v1/jobs/{job_id}/confirm",
            json_payload={"confirmed": True},
        )


def _poll_job(*, app: FastAPI, recorder: LatencyRecorder, job_id: str) -> None:
    with TestClient(app) as client:
        _recorded_get(client=client, recorder=recorder, url=f"/v1/jobs/{job_id}")


def _worker_loop(*, worker, worker_id: str, stop: threading.Event) -> None:
    while not stop.is_set():
        did_work = worker.process_next(worker_id=worker_id)
        if not did_work:
            time.sleep(0.01)


def _start_workers(*, stress_worker_factory) -> tuple[threading.Event, list[threading.Thread]]:
    stop = threading.Event()
    threads: list[threading.Thread] = []
    for i in range(10):
        worker = stress_worker_factory()
        thread = threading.Thread(
            target=_worker_loop,
            kwargs={"worker": worker, "worker_id": f"w{i}", "stop": stop},
        )
        thread.start()
        threads.append(thread)
    return stop, threads


def _run_users(*, app: FastAPI, recorder: LatencyRecorder, users: int) -> list[str]:
    job_ids: list[str] = []
    with ThreadPoolExecutor(max_workers=users) as pool:
        futures = [pool.submit(_create_job, app=app, recorder=recorder) for _ in range(users)]
        for f in as_completed(futures):
            job_ids.append(f.result())
    with ThreadPoolExecutor(max_workers=min(users, 100)) as pool:
        futures = [pool.submit(_preview_job, app=app, recorder=recorder, job_id=j) for j in job_ids]
        for f in as_completed(futures):
            f.result()
    return job_ids


def _run_confirmations(*, app: FastAPI, recorder: LatencyRecorder, job_ids: list[str]) -> None:
    with ThreadPoolExecutor(max_workers=min(len(job_ids), 50)) as pool:
        futures = [pool.submit(_confirm_job, app=app, recorder=recorder, job_id=j) for j in job_ids]
        for f in as_completed(futures):
            f.result()


def _run_polls(
    *,
    app: FastAPI,
    recorder: LatencyRecorder,
    job_ids: list[str],
    queries: int,
) -> None:
    targets = [random.choice(job_ids) for _ in range(queries)]
    with ThreadPoolExecutor(max_workers=min(queries, 100)) as pool:
        futures = [pool.submit(_poll_job, app=app, recorder=recorder, job_id=j) for j in targets]
        for f in as_completed(futures):
            f.result()


def _join_workers(*, stop: threading.Event, threads: list[threading.Thread]) -> None:
    stop.set()
    for t in threads:
        t.join(timeout=5.0)


def test_load_100_concurrent_users_50_runs_200_queries_meets_slo(
    stress_app: FastAPI,
    stress_worker_factory,
    tmp_path: Path,
) -> None:
    users = env_int("SS_STRESS_USERS", 100)
    runs = env_int("SS_STRESS_RUNS", 50)
    queries = env_int("SS_STRESS_QUERIES", 200)

    max_p99_seconds = env_float("SS_STRESS_MAX_P99_SECONDS", 2.0)
    max_error_rate = env_float("SS_STRESS_MAX_ERROR_RATE", 0.001)
    max_rss_mb = env_float("SS_STRESS_MAX_RSS_MB", 500.0)
    max_open_fds = env_int("SS_STRESS_MAX_OPEN_FDS", 1024)

    recorder = LatencyRecorder()
    resources_before = take_resource_snapshot()

    job_ids = _run_users(app=stress_app, recorder=recorder, users=users)
    _run_confirmations(app=stress_app, recorder=recorder, job_ids=job_ids[:runs])

    stop, threads = _start_workers(stress_worker_factory=stress_worker_factory)
    _run_polls(app=stress_app, recorder=recorder, job_ids=job_ids, queries=queries)
    _join_workers(stop=stop, threads=threads)

    summary = recorder.summary()
    resources_after = take_resource_snapshot()
    report = {
        "load": {"users": users, "runs": runs, "queries": queries},
        "latency_ms": {"p50": summary.p50_ms, "p90": summary.p90_ms, "p99": summary.p99_ms},
        "errors": {
            "total": summary.total,
            "errors": summary.errors,
            "error_rate": summary.error_rate,
        },
        "resources": {"before": resources_before.__dict__, "after": resources_after.__dict__},
    }
    write_json_report(path=tmp_path / "stress" / "load_report.json", payload=report)

    assert (summary.p99_ms / 1000.0) < max_p99_seconds
    assert summary.error_rate < max_error_rate

    if resources_after.rss_mb is not None:
        assert resources_after.rss_mb < max_rss_mb
    if resources_after.open_fds is not None:
        assert resources_after.open_fds < max_open_fds


def test_get_job_latency_benchmark(benchmark, stress_app: FastAPI) -> None:
    with TestClient(stress_app) as client:
        response = client.post("/v1/jobs", json={"requirement": f"bench-{uuid.uuid4()}"})
        assert response.status_code == 200
        job_id = response.json()["job_id"]

        def _call() -> None:
            r = client.get(f"/v1/jobs/{job_id}")
            assert r.status_code == 200

        benchmark(_call)
