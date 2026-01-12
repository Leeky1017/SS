from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.output_formatter_data import produce_csv, produce_dta


def _write_csv(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df = pd.DataFrame([{"a": 1, "b": "x"}, {"a": 2, "b": "y"}])
    df.to_csv(path, index=False)


def _write_dta(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df = pd.DataFrame([{"a": 1, "b": "x"}, {"a": 2, "b": "y"}])
    df.to_stata(path, write_index=False)


def test_produce_dta_with_csv_dataset_writes_output_and_returns_dataset_ref(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    src_path = job_dir / "runs" / "run_1" / "artifacts" / "dataset.csv"
    _write_csv(src_path)
    src_ref = ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_DATASET,
        rel_path=src_path.relative_to(job_dir).as_posix(),
    )

    ref, err = produce_dta(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=job_dir / "runs" / "run_1" / "artifacts" / "formatted",
        artifacts=(src_ref,),
    )

    assert err is None
    assert ref is not None
    assert ref.kind == ArtifactKind.STATA_EXPORT_DATASET
    assert (job_dir / ref.rel_path).is_file()
    meta = ref.model_dump().get("meta")
    assert isinstance(meta, dict)
    assert meta.get("output_format") == "dta"


def test_produce_dta_with_csv_table_returns_table_kind(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    src_path = job_dir / "runs" / "run_1" / "artifacts" / "table.csv"
    _write_csv(src_path)
    src_ref = ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_TABLE,
        rel_path=src_path.relative_to(job_dir).as_posix(),
    )

    ref, err = produce_dta(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=job_dir / "runs" / "run_1" / "artifacts" / "formatted",
        artifacts=(src_ref,),
    )

    assert err is None
    assert ref is not None
    assert ref.kind == ArtifactKind.STATA_EXPORT_TABLE


def test_produce_dta_without_csv_falls_back_to_manifest(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    formatted_dir = job_dir / "runs" / "run_1" / "artifacts" / "formatted"
    artifacts = (
        ArtifactRef(kind=ArtifactKind.STATA_LOG, rel_path="runs/run_1/artifacts/stata.log"),
    )

    ref, err = produce_dta(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=formatted_dir,
        artifacts=artifacts,
    )

    assert err is None
    assert ref is not None
    assert ref.kind == ArtifactKind.STATA_EXPORT_MANIFEST
    assert (job_dir / ref.rel_path).is_file()


def test_produce_csv_with_dta_dataset_writes_output_and_returns_dataset_ref(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    src_path = job_dir / "runs" / "run_1" / "artifacts" / "dataset.dta"
    _write_dta(src_path)
    src_ref = ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_DATASET,
        rel_path=src_path.relative_to(job_dir).as_posix(),
    )

    ref, err = produce_csv(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=job_dir / "runs" / "run_1" / "artifacts" / "formatted",
        artifacts=(src_ref,),
    )

    assert err is None
    assert ref is not None
    assert ref.kind == ArtifactKind.STATA_EXPORT_DATASET
    assert (job_dir / ref.rel_path).is_file()
    meta = ref.model_dump().get("meta")
    assert isinstance(meta, dict)
    assert meta.get("output_format") == "csv"


def test_produce_csv_without_dta_falls_back_to_manifest(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    formatted_dir = job_dir / "runs" / "run_1" / "artifacts" / "formatted"
    artifacts = (
        ArtifactRef(kind=ArtifactKind.STATA_LOG, rel_path="runs/run_1/artifacts/stata.log"),
    )

    ref, err = produce_csv(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=formatted_dir,
        artifacts=artifacts,
    )

    assert err is None
    assert ref is not None
    assert ref.kind == ArtifactKind.STATA_EXPORT_MANIFEST
    assert (job_dir / ref.rel_path).is_file()


def test_produce_csv_when_read_stata_fails_returns_error(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    missing = ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_DATASET,
        rel_path="runs/run_1/artifacts/missing.dta",
    )
    ref, err = produce_csv(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=job_dir / "runs" / "run_1" / "artifacts" / "formatted",
        artifacts=(missing,),
    )

    assert ref is None
    assert err is not None
    assert err.error_code == "OUTPUT_FORMATTER_FAILED"


def test_produce_dta_when_read_csv_fails_returns_error(tmp_path: Path) -> None:
    job_dir = tmp_path / "job_123"
    missing = ArtifactRef(
        kind=ArtifactKind.STATA_EXPORT_DATASET,
        rel_path="runs/run_1/artifacts/missing.csv",
    )
    ref, err = produce_dta(
        created_at="2026-01-01T00:00:00Z",
        job_dir=job_dir,
        formatted_dir=job_dir / "runs" / "run_1" / "artifacts" / "formatted",
        artifacts=(missing,),
    )

    assert ref is None
    assert err is not None
    assert err.error_code == "OUTPUT_FORMATTER_FAILED"
