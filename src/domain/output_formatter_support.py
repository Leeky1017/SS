from __future__ import annotations

from pathlib import Path

from src.domain.models import ArtifactKind, ArtifactRef
from src.infra.stata_run_support import job_rel_path


def ext_of(rel_path: str) -> str:
    suffix = Path(rel_path).suffix.lower()
    if suffix.startswith("."):
        return suffix[1:]
    return ""


def formats_present(*, artifacts: tuple[ArtifactRef, ...]) -> set[str]:
    present: set[str] = set()
    for ref in artifacts:
        ext = ext_of(ref.rel_path)
        if ext != "":
            present.add(ext)
    return present


def artifact_path(*, job_dir: Path, ref: ArtifactRef) -> Path:
    return job_dir / ref.rel_path


def artifact_ref_with_meta(
    *,
    job_dir: Path,
    kind: ArtifactKind,
    path: Path,
    created_at: str,
    output_format: str,
) -> ArtifactRef:
    ref = ArtifactRef(
        kind=kind,
        rel_path=job_rel_path(job_dir=job_dir, path=path),
    )
    return ref.model_copy(
        update={
            "created_at": created_at,
            "meta": {"output_format": output_format, "generated_by": "output_formatter"},
        }
    )
