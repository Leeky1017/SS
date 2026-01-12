from __future__ import annotations

from pathlib import Path

import pytest

from src.domain.models import ArtifactKind
from src.domain.stata_runner import RunError
from src.domain.worker_pre_run_error import write_pre_run_error
from src.infra.stata_run_paths import resolve_run_dirs


def test_write_pre_run_error_writes_artifacts_and_returns_result(tmp_path: Path) -> None:
    dirs = resolve_run_dirs(jobs_dir=tmp_path, job_id="job_123", run_id="run_123")
    assert dirs is not None

    error = RunError(error_code="PLAN_INVALID", message="plan invalid")
    result = write_pre_run_error(dirs=dirs, job_id="job_123", run_id="run_123", error=error)

    assert result.ok is False
    assert result.error == error
    assert {ref.kind for ref in result.artifacts} == {
        ArtifactKind.RUN_STDOUT,
        ArtifactKind.RUN_STDERR,
        ArtifactKind.STATA_LOG,
        ArtifactKind.RUN_META_JSON,
        ArtifactKind.RUN_ERROR_JSON,
    }


def test_write_pre_run_error_when_write_fails_returns_structured_error(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    dirs = resolve_run_dirs(jobs_dir=tmp_path, job_id="job_123", run_id="run_123")
    assert dirs is not None

    def _fail_write_run_artifacts(*_args: object, **_kwargs: object) -> object:
        raise OSError("disk full")

    monkeypatch.setattr(
        "src.domain.worker_pre_run_error.write_run_artifacts",
        _fail_write_run_artifacts,
    )

    error = RunError(error_code="PLAN_INVALID", message="plan invalid")
    result = write_pre_run_error(dirs=dirs, job_id="job_123", run_id="run_123", error=error)

    assert result.ok is False
    assert result.artifacts == tuple()
    assert result.error is not None
    assert result.error.error_code == "WORKER_ARTIFACTS_WRITE_FAILED"

