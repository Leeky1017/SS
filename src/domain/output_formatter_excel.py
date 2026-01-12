from __future__ import annotations

from pathlib import Path

import pandas as pd

from src.domain.models import ArtifactKind, ArtifactRef
from src.domain.output_formatter_support import artifact_path, artifact_ref_with_meta, ext_of
from src.domain.stata_runner import RunError


def _manifest_table(*, artifacts: tuple[ArtifactRef, ...]) -> pd.DataFrame:
    return pd.DataFrame(
        [{"kind": ref.kind.value, "rel_path": ref.rel_path} for ref in artifacts],
    )


def _safe_sheet_name(value: str) -> str:
    cleaned = "".join(ch if ch.isalnum() or ch in {"_", "-"} else "_" for ch in value)
    cleaned = cleaned.strip("_")
    if cleaned == "":
        return "sheet"
    return cleaned[:31]


def _unique_sheet_names(stems: list[str]) -> list[str]:
    seen: dict[str, int] = {}
    names: list[str] = []
    for stem in stems:
        base = _safe_sheet_name(stem)
        count = seen.get(base, 0)
        seen[base] = count + 1
        if count == 0:
            names.append(base)
            continue
        suffix = f"_{count + 1}"
        names.append((base[: 31 - len(suffix)] + suffix)[:31])
    return names


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


def _write_xlsx_or_error(
    *,
    src_tables: list[tuple[str, pd.DataFrame]],
    dest_path: Path,
) -> RunError | None:
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    sheet_names = _unique_sheet_names([name for name, _df in src_tables])
    try:
        with pd.ExcelWriter(dest_path, engine="openpyxl") as writer:
            for (_name, df), sheet in zip(src_tables, sheet_names, strict=True):
                df.to_excel(writer, sheet_name=sheet, index=False)
    except (OSError, ValueError) as e:
        return RunError(error_code="OUTPUT_FORMATTER_FAILED", message=str(e))
    return None


def produce_xlsx(
    *,
    created_at: str,
    job_dir: Path,
    formatted_dir: Path,
    artifacts: tuple[ArtifactRef, ...],
) -> tuple[ArtifactRef | None, RunError | None]:
    src_csv = [ref for ref in artifacts if ext_of(ref.rel_path) == "csv"]
    src_dta = [ref for ref in artifacts if ext_of(ref.rel_path) == "dta"]
    tables: list[tuple[str, pd.DataFrame]] = []

    for ref in src_csv:
        df, err = _read_csv_or_error(artifact_path(job_dir=job_dir, ref=ref))
        if err is not None or df is None:
            return None, err
        tables.append((Path(ref.rel_path).stem, df))

    if not tables:
        for ref in src_dta:
            df, err = _read_stata_or_error(artifact_path(job_dir=job_dir, ref=ref))
            if err is not None or df is None:
                return None, err
            tables.append((Path(ref.rel_path).stem, df))

    if not tables:
        tables = [("artifacts", _manifest_table(artifacts=artifacts))]
        out_kind = ArtifactKind.STATA_EXPORT_MANIFEST
    else:
        out_kind = ArtifactKind.STATA_EXPORT_TABLE

    dest_path = formatted_dir / "tables.xlsx"
    err = _write_xlsx_or_error(src_tables=tables, dest_path=dest_path)
    if err is not None:
        return None, err

    return (
        artifact_ref_with_meta(
            job_dir=job_dir,
            kind=out_kind,
            path=dest_path,
            created_at=created_at,
            output_format="xlsx",
        ),
        None,
    )
