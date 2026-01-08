from __future__ import annotations

import csv
from dataclasses import dataclass
from io import StringIO
from pathlib import Path
from typing import cast

from src.utils.json_types import JsonObject, JsonValue


@dataclass(frozen=True)
class CSVJoinError(Exception):
    reason: str


def append_csv(*, primary_path: Path, secondary_path: Path) -> tuple[str, JsonObject]:
    primary_fields, primary_rows = _read_csv(primary_path)
    secondary_fields, secondary_rows = _read_csv(secondary_path)
    if primary_fields != secondary_fields:
        raise CSVJoinError("append_header_mismatch")
    output = _write_csv_rows(fieldnames=primary_fields, rows=[*primary_rows, *secondary_rows])
    stats: JsonObject = {
        "operation": "append",
        "primary_rows": len(primary_rows),
        "secondary_rows": len(secondary_rows),
    }
    return output, stats


def merge_csv(
    *, primary_path: Path, secondary_path: Path, keys: tuple[str, ...]
) -> tuple[str, JsonObject]:
    primary_fields, primary_rows = _read_csv(primary_path)
    secondary_fields, secondary_rows = _read_csv(secondary_path)
    for key in keys:
        if key not in primary_fields or key not in secondary_fields:
            raise CSVJoinError("merge_key_missing")

    index: dict[tuple[str, ...], dict[str, str]] = {}
    for row in secondary_rows:
        join_key = tuple(row.get(k, "") for k in keys)
        if join_key in index:
            raise CSVJoinError("merge_key_duplicate")
        index[join_key] = dict(row)

    merged_rows: list[dict[str, str]] = []
    matches = 0
    for row in primary_rows:
        out = dict(row)
        join_key = tuple(row.get(k, "") for k in keys)
        rhs = index.get(join_key)
        if rhs is not None:
            matches += 1
            for col, value in rhs.items():
                if col in keys:
                    continue
                if col in out:
                    out[f"{col}_rhs"] = value
                else:
                    out[col] = value
        merged_rows.append(out)

    fieldnames = _merged_fieldnames(
        primary_fields=primary_fields,
        secondary_fields=secondary_fields,
        keys=keys,
    )
    output = _write_csv_rows(fieldnames=fieldnames, rows=merged_rows)
    stats: JsonObject = {
        "operation": "merge",
        "keys": [cast(JsonValue, k) for k in keys],
        "primary_rows": len(primary_rows),
        "secondary_rows": len(secondary_rows),
        "matched_rows": matches,
        "unmatched_rows": len(primary_rows) - matches,
    }
    return output, stats


def _merged_fieldnames(
    *, primary_fields: list[str], secondary_fields: list[str], keys: tuple[str, ...]
) -> list[str]:
    fieldnames = list(primary_fields)
    for col in secondary_fields:
        if col in keys:
            continue
        if col in fieldnames:
            fieldnames.append(f"{col}_rhs")
        else:
            fieldnames.append(col)
    return fieldnames


def _read_csv(path: Path) -> tuple[list[str], list[dict[str, str]]]:
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fields = [] if reader.fieldnames is None else list(reader.fieldnames)
        if len(fields) == 0:
            raise CSVJoinError("csv_missing_header")
        return fields, rows


def _write_csv_rows(*, fieldnames: list[str], rows: list[dict[str, str]]) -> str:
    buf = StringIO()
    writer = csv.DictWriter(buf, fieldnames=fieldnames, extrasaction="ignore")
    writer.writeheader()
    for row in rows:
        writer.writerow(row)
    return buf.getvalue()
