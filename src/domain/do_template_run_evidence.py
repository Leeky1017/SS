from __future__ import annotations

from pathlib import Path

from src.domain.do_template_run_support import (
    append_artifact_if_missing,
    artifact_ref,
    copy_output_or_skip,
    declared_outputs,
    output_filename,
    output_kind,
    write_artifact_json,
    write_artifact_text,
)
from src.domain.models import ArtifactKind, ArtifactRef


def write_template_evidence(
    *,
    job_id: str,
    run_id: str,
    template_id: str,
    raw_do: str,
    meta: dict,
    params: dict[str, str],
    artifacts_dir: Path,
    job_dir: Path,
) -> tuple[ArtifactRef, ...]:
    template_dir = artifacts_dir / "template"
    source_path = template_dir / "source.do"
    meta_path = template_dir / "meta.json"
    params_path = template_dir / "params.json"
    write_artifact_text(
        template_id=template_id,
        job_id=job_id,
        run_id=run_id,
        path=source_path,
        content=raw_do,
    )
    write_artifact_json(
        template_id=template_id,
        job_id=job_id,
        run_id=run_id,
        path=meta_path,
        payload=meta,
    )
    write_artifact_json(
        template_id=template_id,
        job_id=job_id,
        run_id=run_id,
        path=params_path,
        payload=params,
    )
    return (
        artifact_ref(job_dir=job_dir, kind=ArtifactKind.DO_TEMPLATE_SOURCE, path=source_path),
        artifact_ref(job_dir=job_dir, kind=ArtifactKind.DO_TEMPLATE_META, path=meta_path),
        artifact_ref(job_dir=job_dir, kind=ArtifactKind.DO_TEMPLATE_PARAMS, path=params_path),
    )


def archive_outputs(
    *,
    template_id: str,
    meta: dict,
    work_dir: Path,
    artifacts_dir: Path,
    job_dir: Path,
) -> tuple[tuple[ArtifactRef, ...], tuple[str, ...]]:
    outputs_dir = artifacts_dir / "outputs"
    outputs_dir.mkdir(parents=True, exist_ok=True)
    refs: list[ArtifactRef] = []
    missing: list[str] = []
    for output in declared_outputs(template_id=template_id, meta=meta):
        filename = output_filename(template_id=template_id, output=output)
        src = work_dir / filename
        dst = outputs_dir / filename
        ok = copy_output_or_skip(src=src, dst=dst)
        if not ok:
            missing.append(filename)
            continue
        ref = artifact_ref(job_dir=job_dir, kind=output_kind(output), path=dst)
        append_artifact_if_missing(refs=refs, ref=ref)
    return tuple(refs), tuple(sorted(set(missing)))


def write_run_meta(
    *,
    job_id: str,
    run_id: str,
    template_id: str,
    params: dict[str, str],
    archived_outputs: tuple[ArtifactRef, ...],
    missing_outputs: tuple[str, ...],
    artifacts_dir: Path,
    job_dir: Path,
) -> ArtifactRef:
    path = artifacts_dir / "do_template_run.meta.json"
    payload = {
        "job_id": job_id,
        "run_id": run_id,
        "template_id": template_id,
        "params": params,
        "archived_outputs": [ref.rel_path for ref in archived_outputs],
        "missing_outputs": list(missing_outputs),
    }
    write_artifact_json(
        template_id=template_id,
        job_id=job_id,
        run_id=run_id,
        path=path,
        payload=payload,
    )
    return artifact_ref(job_dir=job_dir, kind=ArtifactKind.DO_TEMPLATE_RUN_META_JSON, path=path)
