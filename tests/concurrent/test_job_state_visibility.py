from __future__ import annotations

import threading
import time
from dataclasses import dataclass
from pathlib import Path

from src.domain.models import JobStatus
from src.domain.stata_runner import RunResult, StataRunner
from src.domain.worker_service import WorkerRetryPolicy, WorkerService
from src.infra.job_store import JobStore


@dataclass(frozen=True)
class BlockingStataRunner(StataRunner):
    allow_finish: threading.Event
    started: threading.Event

    def run(
        self,
        *,
        tenant_id: str = "default",
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ) -> RunResult:
        self.started.set()
        self.allow_finish.wait(timeout=5.0)
        return RunResult(
            job_id=job_id,
            run_id=run_id,
            ok=True,
            exit_code=0,
            timed_out=False,
            artifacts=tuple(),
            error=None,
        )


def test_worker_progress_is_visible_while_user_polls_status(
    create_queued_job,
    jobs_dir: Path,
    store: JobStore,
    queue,
    queue_dir,
    state_machine,
    noop_sleep,
) -> None:
    job_id = create_queued_job("hello")
    allow_finish = threading.Event()
    started = threading.Event()

    service = WorkerService(
        store=store,
        queue=queue,
        jobs_dir=jobs_dir,
        runner=BlockingStataRunner(allow_finish=allow_finish, started=started),
        state_machine=state_machine,
        retry=WorkerRetryPolicy(max_attempts=1, backoff_base_seconds=0.0, backoff_max_seconds=0.0),
        sleep=noop_sleep,
    )

    processed: list[bool] = []

    def _worker() -> None:
        processed.append(service.process_next(worker_id="worker-1"))

    thread = threading.Thread(target=_worker, daemon=True)
    thread.start()

    assert started.wait(timeout=2.0)
    observed_running = False
    deadline = time.monotonic() + 1.0
    while time.monotonic() < deadline and not allow_finish.is_set():
        job = store.load(job_id)
        if job.status == JobStatus.RUNNING:
            observed_running = True
            assert job.runs
            assert job.runs[-1].status in {"running", "succeeded"}
        time.sleep(0.005)

    assert observed_running is True
    allow_finish.set()
    thread.join(timeout=2.0)
    assert thread.is_alive() is False
    assert processed == [True]

    done = store.load(job_id)
    assert done.status == JobStatus.SUCCEEDED
    assert done.runs
    assert done.runs[-1].status == "succeeded"

    assert list((queue_dir / "queued").glob("*.json")) == []
    assert list((queue_dir / "claimed").glob("*.json")) == []
