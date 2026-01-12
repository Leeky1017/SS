from __future__ import annotations

import json
import logging
from pathlib import Path

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.stata_runner import RunError
from src.infra.stata_run_support import ERROR_FILENAME, job_rel_path

logger = logging.getLogger(__name__)


def write_run_error_artifact(
    *,
    job_dir: Path,
    artifacts_dir: Path,
    error: RunError,
) -> ArtifactRef | None:
    path = artifacts_dir / ERROR_FILENAME
    if path.exists():
        return None

    payload: dict[str, object] = {
        "error_code": error.error_code,
        "message": error.message,
        "timed_out": False,
        "exit_code": None,
    }
    if error.details is not None:
        payload["details"] = error.details

    try:
        path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    except OSError as e:
        logger.warning(
            "SS_OUTPUT_FORMATTER_WRITE_ERROR_FAILED",
            extra={"job_id": job_dir.name, "reason": str(e)},
        )
        return None

    return ArtifactRef(
        kind=ArtifactKind.RUN_ERROR_JSON,
        rel_path=job_rel_path(job_dir=job_dir, path=path),
    )

