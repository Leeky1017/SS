from __future__ import annotations

import json
from pathlib import Path

from src.domain.output_formatter_error import write_run_error_artifact
from src.domain.stata_runner import RunError
from src.infra.stata_run_support import ERROR_FILENAME


def test_write_run_error_artifact_when_missing_writes_file_and_returns_ref(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    artifacts_dir = job_dir / "runs" / "run_1" / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    error = RunError(error_code="OUTPUT_FORMATTER_FAILED", message="boom", details={"x": 1})
    ref = write_run_error_artifact(job_dir=job_dir, artifacts_dir=artifacts_dir, error=error)

    assert ref is not None
    assert ref.rel_path.endswith(ERROR_FILENAME)
    payload = json.loads((artifacts_dir / ERROR_FILENAME).read_text(encoding="utf-8"))
    assert payload["error_code"] == "OUTPUT_FORMATTER_FAILED"
    assert payload["message"] == "boom"
    assert payload["details"] == {"x": 1}


def test_write_run_error_artifact_when_file_exists_returns_none(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    artifacts_dir = job_dir / "runs" / "run_1" / "artifacts"
    artifacts_dir.mkdir(parents=True, exist_ok=True)

    existing = artifacts_dir / ERROR_FILENAME
    existing.write_text("{}", encoding="utf-8")

    error = RunError(error_code="OUTPUT_FORMATTER_FAILED", message="boom")
    ref = write_run_error_artifact(job_dir=job_dir, artifacts_dir=artifacts_dir, error=error)

    assert ref is None
    assert existing.read_text(encoding="utf-8") == "{}"


def test_write_run_error_artifact_when_write_fails_returns_none(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    artifacts_dir = job_dir / "runs" / "run_1" / "artifacts"
    error = RunError(error_code="OUTPUT_FORMATTER_FAILED", message="boom")

    ref = write_run_error_artifact(job_dir=job_dir, artifacts_dir=artifacts_dir, error=error)

    assert ref is None

