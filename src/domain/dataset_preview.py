from __future__ import annotations

from datetime import date, datetime
from pathlib import Path
from typing import Any, cast

from src.utils.json_types import JsonObject


def _jsonable_value(value: Any) -> str | int | float | bool | None:
    if value is None:
        return None
    if isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    item = getattr(value, "item", None)
    if callable(item):
        return _jsonable_value(item())
    return str(value)


def _read_preview_frame(*, path: Path, fmt: str, rows: int):
    import pandas as pd

    if fmt == "csv":
        return pd.read_csv(path, nrows=rows)
    if fmt == "excel":
        engine = "xlrd" if path.suffix.lower() == ".xls" else "openpyxl"
        return pd.read_excel(path, nrows=rows, engine=engine)
    if fmt == "dta":
        it = pd.read_stata(path, chunksize=rows)
        try:
            return next(it)
        except StopIteration:
            return pd.DataFrame()
    raise ValueError(f"unsupported format: {fmt}")


def _infer_columns(*, df, columns: int) -> list[dict[str, str]]:
    import pandas as pd

    types = pd.api.types
    limited = df.iloc[:, :columns]
    columns_preview: list[dict[str, str]] = []
    for col in limited.columns:
        dtype = limited[col].dtype
        inferred = "unknown"
        if types.is_bool_dtype(dtype):
            inferred = "boolean"
        elif types.is_integer_dtype(dtype):
            inferred = "integer"
        elif types.is_float_dtype(dtype):
            inferred = "number"
        elif types.is_datetime64_any_dtype(dtype):
            inferred = "datetime"
        elif types.is_string_dtype(dtype) or types.is_object_dtype(dtype):
            inferred = "string"
        columns_preview.append({"name": str(col), "inferred_type": inferred})
    return columns_preview


def _sample_rows(*, df, columns: int) -> list[dict[str, str | int | float | bool | None]]:
    limited = df.iloc[:, :columns]
    raw_rows = limited.to_dict(orient="records")
    sample_rows: list[dict[str, str | int | float | bool | None]] = []
    for row in cast(list[dict[str, Any]], raw_rows):
        sample_rows.append({str(k): _jsonable_value(v) for k, v in row.items()})
    return sample_rows


def dataset_preview(*, path: Path, fmt: str, rows: int, columns: int) -> JsonObject:
    df = _read_preview_frame(path=path, fmt=fmt, rows=rows)
    return cast(
        JsonObject,
        {
            "row_count": None,
            "columns": _infer_columns(df=df, columns=columns),
            "sample_rows": _sample_rows(df=df, columns=columns),
        },
    )
