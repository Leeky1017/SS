from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.output_formatter_support import artifact_path, artifact_ref_with_meta, ext_of
from src.domain.stata_runner import RunError


def _manifest_df(*, artifacts: tuple[ArtifactRef, ...]) -> pd.DataFrame:
    return pd.DataFrame(
        [{"kind": ref.kind.value, "rel_path": ref.rel_path} for ref in artifacts],
    )


def _read_csv_or_error(path: Path) -> tuple[pd.DataFrame | None, RunError | None]:
    try:
        return pd.read_csv(path), None
    except (FileNotFoundError, OSError, UnicodeDecodeError, ValueError) as e:
        return None, RunError(error_code="OUTPUT_FORMATTER_FAILED", message=str(e))


def _read_stata_or_error(path: Path) -> tuple[pd.DataFrame | None, RunError | None]:
    try:
        return pd.read_stata(path), None
    except (FileNotFoundError, OSError, ValueError) as e:
        return None, RunError(error_code="OUTPUT_FORMATTER_FAILED", message=str(e))


def _write_dta_or_error(*, df: pd.DataFrame, dest_path: Path) -> RunError | None:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        df.to_stata(dest_path, write_index=False)
    except (OSError, ValueError) as e:
        return RunError(error_code="OUTPUT_FORMATTER_FAILED", message=str(e))
    return None


def _write_csv_or_error(*, df: pd.DataFrame, dest_path: Path) -> RunError | None:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    try:
        df.to_csv(dest_path, index=False)
    except (OSError, ValueError) as e:
        return RunError(error_code="OUTPUT_FORMATTER_FAILED", message=str(e))
    return None


def produce_dta(
    *,
    created_at: str,
    job_dir: Path,
    formatted_dir: Path,
    artifacts: tuple[ArtifactRef, ...],
) -> tuple[ArtifactRef | None, RunError | None]:
    src_csv = [ref for ref in artifacts if ext_of(ref.rel_path) == "csv"]
    if not src_csv:
        manifest_df = _manifest_df(artifacts=artifacts)
        dest_path = formatted_dir / "output.dta"
        err = _write_dta_or_error(df=manifest_df, dest_path=dest_path)
        if err is not None:
            return None, err
        return (
            artifact_ref_with_meta(
                job_dir=job_dir,
                kind=ArtifactKind.STATA_EXPORT_MANIFEST,
                path=dest_path,
                created_at=created_at,
                output_format="dta",
            ),
            None,
        )

    preferred = next(
        (ref for ref in src_csv if ref.kind == ArtifactKind.STATA_EXPORT_DATASET),
        src_csv[0],
    )
    df, err = _read_csv_or_error(artifact_path(job_dir=job_dir, ref=preferred))
    if err is not None or df is None:
        return None, err

    dest_path = formatted_dir / "output.dta"
    err = _write_dta_or_error(df=df, dest_path=dest_path)
    if err is not None:
        return None, err

    kind = (
        ArtifactKind.STATA_EXPORT_DATASET
        if preferred.kind == ArtifactKind.STATA_EXPORT_DATASET
        else ArtifactKind.STATA_EXPORT_TABLE
    )
    return (
        artifact_ref_with_meta(
            job_dir=job_dir,
            kind=kind,
            path=dest_path,
            created_at=created_at,
            output_format="dta",
        ),
        None,
    )


def produce_csv(
    *,
    created_at: str,
    job_dir: Path,
    formatted_dir: Path,
    artifacts: tuple[ArtifactRef, ...],
) -> tuple[ArtifactRef | None, RunError | None]:
    src_dta = [ref for ref in artifacts if ext_of(ref.rel_path) == "dta"]
    if not src_dta:
        manifest_df = _manifest_df(artifacts=artifacts)
        dest_path = formatted_dir / "output.csv"
        err = _write_csv_or_error(df=manifest_df, dest_path=dest_path)
        if err is not None:
            return None, err
        return (
            artifact_ref_with_meta(
                job_dir=job_dir,
                kind=ArtifactKind.STATA_EXPORT_MANIFEST,
                path=dest_path,
                created_at=created_at,
                output_format="csv",
            ),
            None,
        )

    preferred = next(
        (ref for ref in src_dta if ref.kind == ArtifactKind.STATA_EXPORT_DATASET),
        src_dta[0],
    )
    df, err = _read_stata_or_error(artifact_path(job_dir=job_dir, ref=preferred))
    if err is not None or df is None:
        return None, err

    dest_path = formatted_dir / "output.csv"
    err = _write_csv_or_error(df=df, dest_path=dest_path)
    if err is not None:
        return None, err

    kind = (
        ArtifactKind.STATA_EXPORT_DATASET
        if preferred.kind == ArtifactKind.STATA_EXPORT_DATASET
        else ArtifactKind.STATA_EXPORT_TABLE
    )
    return (
        artifact_ref_with_meta(
            job_dir=job_dir,
            kind=kind,
            path=dest_path,
            created_at=created_at,
            output_format="csv",
        ),
        None,
    )
