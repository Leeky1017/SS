from __future__ import annotations

import json
import subprocess
from pathlib import Path

from src.domain.models import ArtifactKind
from src.infra.local_stata_runner import LocalStataRunner


def test_run_when_subprocess_succeeds_writes_artifacts_and_returns_ok(job_service, jobs_dir: Path):
    # Arrange
    job = job_service.create_job(requirement="ok")
    run_id = "run_ok"
    expected_work_dir = jobs_dir / job.job_id / "runs" / run_id / "work"

    def fake_run(cmd, *, cwd, timeout, text, capture_output, check):
        assert cmd[-3:] == ["-b", "do", "stata.do"]
        assert cwd == str(expected_work_dir)
        assert (Path(cwd) / "stata.do").exists()
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="hello\n", stderr="")

    runner = LocalStataRunner(jobs_dir=jobs_dir, stata_cmd=["stata"], subprocess_runner=fake_run)

    # Act
    result = runner.run(job_id=job.job_id, run_id=run_id, do_file="display 1\n", timeout_seconds=3)

    # Assert
    assert result.ok is True
    assert result.exit_code == 0
    assert result.timed_out is False
    assert result.error is None

    artifacts_dir = jobs_dir / job.job_id / "runs" / run_id / "artifacts"
    assert (artifacts_dir / "stata.do").exists()
    assert (artifacts_dir / "run.stdout").read_text(encoding="utf-8") == "hello\n"
    assert (artifacts_dir / "run.stderr").read_text(encoding="utf-8") == ""
    assert (artifacts_dir / "stata.log").read_text(encoding="utf-8") == "hello\n"
    assert (artifacts_dir / "run.meta.json").exists()

    kinds = {a.kind for a in result.artifacts}
    assert ArtifactKind.RUN_ERROR_JSON not in kinds


def test_run_when_subprocess_returns_nonzero_writes_error_artifact_and_returns_failed(
    job_service,
    jobs_dir: Path,
):
    # Arrange
    job = job_service.create_job(requirement="bad")
    run_id = "run_nonzero"

    def fake_run(cmd, *, cwd, timeout, text, capture_output, check):
        return subprocess.CompletedProcess(args=cmd, returncode=9, stdout="out", stderr="err")

    runner = LocalStataRunner(jobs_dir=jobs_dir, stata_cmd=["stata"], subprocess_runner=fake_run)

    # Act
    result = runner.run(job_id=job.job_id, run_id=run_id, do_file="bad\n", timeout_seconds=3)

    # Assert
    assert result.ok is False
    assert result.exit_code == 9
    assert result.timed_out is False
    assert result.error is not None
    assert result.error.error_code == "STATA_NONZERO_EXIT"

    artifacts_dir = jobs_dir / job.job_id / "runs" / run_id / "artifacts"
    error_path = artifacts_dir / "run.error.json"
    assert error_path.exists()
    payload = json.loads(error_path.read_text(encoding="utf-8"))
    assert payload["error_code"] == "STATA_NONZERO_EXIT"


def test_run_when_subprocess_times_out_writes_error_artifact_and_returns_failed(
    job_service,
    jobs_dir: Path,
):
    # Arrange
    job = job_service.create_job(requirement="timeout")
    run_id = "run_timeout"

    def fake_run(cmd, *, cwd, timeout, text, capture_output, check):
        raise subprocess.TimeoutExpired(cmd=cmd, timeout=timeout, output="partial", stderr="late")

    runner = LocalStataRunner(jobs_dir=jobs_dir, stata_cmd=["stata"], subprocess_runner=fake_run)

    # Act
    result = runner.run(job_id=job.job_id, run_id=run_id, do_file="sleep\n", timeout_seconds=1)

    # Assert
    assert result.ok is False
    assert result.exit_code is None
    assert result.timed_out is True
    assert result.error is not None
    assert result.error.error_code == "STATA_TIMEOUT"

    artifacts_dir = jobs_dir / job.job_id / "runs" / run_id / "artifacts"
    assert (artifacts_dir / "run.stdout").read_text(encoding="utf-8") == "partial"
    assert (artifacts_dir / "run.stderr").read_text(encoding="utf-8") == "late"
    assert (artifacts_dir / "run.error.json").exists()
