from __future__ import annotations

import logging
from pathlib import Path
from typing import cast

from src.domain.job_store import JobStore
from src.domain.models import is_safe_job_rel_path
from src.infra.exceptions import ArtifactNotFoundError, ArtifactPathUnsafeError
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


class ArtifactsService:
    def __init__(self, *, store: JobStore, jobs_dir: Path):
        self._store = store
        self._jobs_dir = Path(jobs_dir)

    def list_artifacts(self, *, job_id: str) -> list[JsonObject]:
        job = self._store.load(job_id)
        items: list[JsonObject] = []
        for ref in job.artifacts_index:
            extra = ref.model_extra if ref.model_extra is not None else {}
            created_at = extra.get("created_at")
            if not isinstance(created_at, str):
                created_at = None
            meta = extra.get("meta", {})
            if not isinstance(meta, dict):
                meta = {}
            items.append(
                {
                    "kind": ref.kind.value,
                    "rel_path": ref.rel_path,
                    "created_at": created_at,
                    "meta": cast(JsonObject, meta),
                }
            )
        return items

    def resolve_download_path(self, *, job_id: str, rel_path: str) -> Path:
        if not is_safe_job_rel_path(rel_path):
            logger.warning(
                "SS_ARTIFACT_PATH_UNSAFE",
                extra={"job_id": job_id, "rel_path": rel_path, "reason": "unsafe_rel_path"},
            )
            raise ArtifactPathUnsafeError(job_id=job_id, rel_path=rel_path)

        job = self._store.load(job_id)
        if not any(ref.rel_path == rel_path for ref in job.artifacts_index):
            raise ArtifactNotFoundError(job_id=job_id, rel_path=rel_path)

        base = (self._jobs_dir / job_id).resolve(strict=False)
        candidate = self._jobs_dir / job_id / rel_path
        try:
            resolved = candidate.resolve(strict=True)
        except FileNotFoundError as e:
            raise ArtifactNotFoundError(job_id=job_id, rel_path=rel_path) from e

        if not resolved.is_relative_to(base):
            logger.warning(
                "SS_ARTIFACT_PATH_UNSAFE",
                extra={"job_id": job_id, "rel_path": rel_path, "reason": "symlink_escape"},
            )
            raise ArtifactPathUnsafeError(job_id=job_id, rel_path=rel_path)

        if not resolved.is_file():
            raise ArtifactNotFoundError(job_id=job_id, rel_path=rel_path)

        return resolved
