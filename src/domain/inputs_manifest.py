from __future__ import annotations

import hashlib
import json
from collections.abc import Mapping, Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from src.infra.input_exceptions import (
    InputFilenameUnsafeError,
    InputRoleInvalidError,
    InputUnsupportedFormatError,
)
from src.utils.job_workspace import is_safe_path_segment
from src.utils.json_types import JsonObject, JsonValue

INPUTS_DIR = "inputs"
MANIFEST_REL_PATH = f"{INPUTS_DIR}/manifest.json"

MANIFEST_SCHEMA_VERSION_V1 = 1
MANIFEST_SCHEMA_VERSION_V2 = 2

ROLE_PRIMARY_DATASET = "primary_dataset"
ROLE_SECONDARY_DATASET = "secondary_dataset"
ROLE_AUXILIARY_DATA = "auxiliary_data"
ROLE_OTHER = "other"

ALLOWED_DATASET_ROLES = {
    ROLE_PRIMARY_DATASET,
    ROLE_SECONDARY_DATASET,
    ROLE_AUXILIARY_DATA,
    ROLE_OTHER,
}

_ROLE_SORT_ORDER = {
    ROLE_PRIMARY_DATASET: 0,
    ROLE_SECONDARY_DATASET: 1,
    ROLE_AUXILIARY_DATA: 2,
    ROLE_OTHER: 3,
}


@dataclass(frozen=True)
class PreparedDataset:
    dataset_key: str
    role: str
    rel_path: str
    sha256: str
    fingerprint: str
    format: str
    original_name: str
    size_bytes: int
    uploaded_at: str
    content_type: str | None
    data: bytes


def safe_filename(*, original_name: str | None, override_name: str | None) -> str:
    candidate = override_name if override_name is not None else original_name
    if candidate is None:
        raise InputFilenameUnsafeError(filename="")
    name = candidate.strip()
    if name == "" or not is_safe_path_segment(name):
        raise InputFilenameUnsafeError(filename=candidate)
    return name


def validate_dataset_role(role: str) -> str:
    candidate = role.strip()
    if candidate in ALLOWED_DATASET_ROLES:
        return candidate
    raise InputRoleInvalidError(role=role)


def format_from_filename(filename: str) -> tuple[str, str]:
    ext = Path(filename).suffix.lower()
    if ext == ".csv":
        return "csv", ext
    if ext in {".xls", ".xlsx"}:
        return "excel", ext
    if ext == ".dta":
        return "dta", ext
    raise InputUnsupportedFormatError(filename=filename)


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def dataset_key_from_sha256(sha256: str) -> str:
    return f"ds_{sha256[:16]}"


def dataset_rel_path(*, dataset_key: str, ext: str) -> str:
    return f"{INPUTS_DIR}/{dataset_key}{ext}"


def prepare_dataset(
    *,
    data: bytes,
    original_name: str | None,
    filename_override: str | None,
    role: str,
    content_type: str | None,
    uploaded_at: str,
) -> PreparedDataset:
    safe_name = safe_filename(original_name=original_name, override_name=filename_override)
    fmt, ext = format_from_filename(safe_name)
    sha256 = sha256_hex(data)
    dataset_key = dataset_key_from_sha256(sha256)
    rel_path = dataset_rel_path(dataset_key=dataset_key, ext=ext)
    return PreparedDataset(
        dataset_key=dataset_key,
        role=validate_dataset_role(role),
        rel_path=rel_path,
        sha256=sha256,
        fingerprint=f"sha256:{sha256}",
        format=fmt,
        original_name=safe_name,
        size_bytes=len(data),
        uploaded_at=uploaded_at,
        content_type=content_type,
        data=data,
    )


def manifest_payload(*, datasets: Sequence[PreparedDataset]) -> JsonObject:
    def _sort_key(item: PreparedDataset) -> tuple[int, str]:
        return (_ROLE_SORT_ORDER.get(item.role, 99), item.dataset_key)

    payload_datasets: list[JsonObject] = []
    for item in sorted(datasets, key=_sort_key):
        payload_datasets.append(
            {
                "dataset_key": item.dataset_key,
                "role": item.role,
                "rel_path": item.rel_path,
                "original_name": item.original_name,
                "size_bytes": item.size_bytes,
                "sha256": item.sha256,
                "fingerprint": item.fingerprint,
                "format": item.format,
                "uploaded_at": item.uploaded_at,
                "content_type": item.content_type,
            }
        )
    return cast(
        JsonObject,
        {
            "schema_version": MANIFEST_SCHEMA_VERSION_V2,
            "datasets": payload_datasets,
        },
    )


def inputs_fingerprint(*, datasets: Sequence[PreparedDataset]) -> str:
    canonical = [
        {"sha256": item.sha256, "size_bytes": item.size_bytes, "role": item.role}
        for item in sorted(datasets, key=lambda d: (d.role, d.sha256))
    ]
    encoded = json.dumps(
        canonical,
        ensure_ascii=False,
        separators=(",", ":"),
        sort_keys=True,
    ).encode("utf-8")
    sha256 = hashlib.sha256(encoded).hexdigest()
    return f"sha256:{sha256}"


def read_manifest_json(path: Path) -> JsonObject:
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError("manifest must be a JSON object")
    return cast(JsonObject, raw)


def primary_dataset_details(manifest: Mapping[str, object]) -> tuple[str, str, str]:
    datasets = manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            role = item.get("role")
            if role != ROLE_PRIMARY_DATASET:
                continue
            rel_path = item.get("rel_path")
            if not isinstance(rel_path, str) or rel_path.strip() == "":
                raise ValueError("manifest missing datasets[].rel_path")
            fmt = item.get("format")
            if not isinstance(fmt, str) or fmt.strip() == "":
                raise ValueError("manifest missing datasets[].format")
            original_name = item.get("original_name")
            if not isinstance(original_name, str) or original_name.strip() == "":
                original_name = rel_path
            return rel_path, fmt, original_name
        raise ValueError("manifest missing primary_dataset role")

    primary = manifest.get("primary_dataset")
    if not isinstance(primary, Mapping):
        raise ValueError("manifest missing primary_dataset")
    rel_path = primary.get("rel_path")
    if not isinstance(rel_path, str) or rel_path.strip() == "":
        raise ValueError("manifest missing primary_dataset.rel_path")
    fmt = primary.get("format")
    if not isinstance(fmt, str) or fmt.strip() == "":
        raise ValueError("manifest missing primary_dataset.format")
    original_name = primary.get("original_name")
    if not isinstance(original_name, str) or original_name.strip() == "":
        original_name = rel_path
    return rel_path, fmt, original_name


def _sheet_name_or_none(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    candidate = value.strip()
    return None if candidate == "" else candidate


def _bool_or_none(value: object) -> bool | None:
    if isinstance(value, bool):
        return value
    return None


def primary_dataset_excel_options(manifest: Mapping[str, object]) -> tuple[str | None, bool | None]:
    datasets = manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            if item.get("role") != ROLE_PRIMARY_DATASET:
                continue
            return _sheet_name_or_none(item.get("sheet_name")), _bool_or_none(
                item.get("header_row")
            )

    primary = manifest.get("primary_dataset")
    if isinstance(primary, Mapping):
        return _sheet_name_or_none(primary.get("sheet_name")), _bool_or_none(
            primary.get("header_row")
        )
    return _sheet_name_or_none(manifest.get("primary_dataset_sheet_name")), _bool_or_none(
        manifest.get("primary_dataset_header_row")
    )


def set_primary_dataset_excel_options(
    manifest: JsonObject, *, sheet_name: str | None, header_row: bool | None
) -> JsonObject:
    def _apply(item: JsonObject) -> JsonObject:
        updated = dict(item)
        if sheet_name is None:
            updated.pop("sheet_name", None)
        else:
            updated["sheet_name"] = sheet_name
        if header_row is None:
            updated.pop("header_row", None)
        else:
            updated["header_row"] = header_row
        return updated

    datasets_obj = manifest.get("datasets")
    if isinstance(datasets_obj, list):
        updated_datasets: list[JsonValue] = []
        applied = False
        for raw in datasets_obj:
            if isinstance(raw, dict) and raw.get("role") == ROLE_PRIMARY_DATASET and not applied:
                updated_datasets.append(_apply(raw))
                applied = True
            else:
                updated_datasets.append(raw)
        if not applied:
            return manifest
        out = dict(manifest)
        out["datasets"] = updated_datasets
        return out

    primary_obj = manifest.get("primary_dataset")
    if isinstance(primary_obj, dict):
        out = dict(manifest)
        out["primary_dataset"] = _apply(primary_obj)
        return out

    out = dict(manifest)
    if sheet_name is None:
        out.pop("primary_dataset_sheet_name", None)
    else:
        out["primary_dataset_sheet_name"] = sheet_name
    if header_row is None:
        out.pop("primary_dataset_header_row", None)
    else:
        out["primary_dataset_header_row"] = header_row
    return out
