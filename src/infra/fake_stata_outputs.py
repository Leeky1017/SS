from __future__ import annotations

import logging
from pathlib import Path

from src.domain.do_file_generator import DEFAULT_SUMMARY_TABLE_FILENAME
from src.domain.models import ArtifactKind, ArtifactRef
from src.infra.stata_run_support import job_rel_path, write_text

logger = logging.getLogger(__name__)


def export_table_ref(
    *,
    job_dir: Path,
    artifacts_dir: Path,
    job_id: str,
    run_id: str,
    ok: bool,
) -> ArtifactRef | None:
    if not ok:
        return None
    path = artifacts_dir / DEFAULT_SUMMARY_TABLE_FILENAME
    content = "metric,value\nN,0\nk,0\n"
    try:
        write_text(path, content)
    except OSError as e:
        logger.warning(
            "SS_FAKE_STATA_WRITE_EXPORT_TABLE_FAILED",
            extra={"job_id": job_id, "run_id": run_id, "path": str(path), "reason": str(e)},
        )
        return None
    return ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_TABLE,
        rel_path=job_rel_path(job_dir=job_dir, path=path),
    )
