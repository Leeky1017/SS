from __future__ import annotations

from collections.abc import Mapping
from typing import cast

from src.utils.json_types import JsonObject, JsonValue


def dataset_details(
    manifest: Mapping[str, object], *, dataset_key: str
) -> tuple[str, str, str, str]:
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list):
        raise ValueError("manifest missing datasets[]")

    target = dataset_key.strip()
    if target == "":
        raise ValueError("dataset_key empty")

    for item in datasets:
        if not isinstance(item, Mapping):
            continue
        if item.get("dataset_key") != target:
            continue
        rel_path = item.get("rel_path")
        if not isinstance(rel_path, str) or rel_path.strip() == "":
            raise ValueError("manifest missing datasets[].rel_path")
        fmt = item.get("format")
        if not isinstance(fmt, str) or fmt.strip() == "":
            raise ValueError("manifest missing datasets[].format")
        role = item.get("role")
        if not isinstance(role, str) or role.strip() == "":
            role = "other"
        original_name = item.get("original_name")
        if not isinstance(original_name, str) or original_name.strip() == "":
            original_name = rel_path
        return rel_path, fmt, original_name, role
    raise ValueError("dataset_key not found")


def _sheet_name_or_none(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    candidate = value.strip()
    return None if candidate == "" else candidate


def _bool_or_none(value: object) -> bool | None:
    if isinstance(value, bool):
        return value
    return None


def primary_dataset_key(manifest: Mapping[str, object]) -> str:
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list):
        raise ValueError("manifest missing datasets[]")
    for item in datasets:
        if not isinstance(item, Mapping):
            continue
        if item.get("role") != "primary_dataset":
            continue
        key = item.get("dataset_key")
        if not isinstance(key, str) or key.strip() == "":
            raise ValueError("manifest missing datasets[].dataset_key")
        return key
    raise ValueError("manifest missing primary_dataset role")


def dataset_excel_options(
    manifest: Mapping[str, object], *, dataset_key: str
) -> tuple[str | None, bool | None]:
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list):
        return None, None
    for item in datasets:
        if not isinstance(item, Mapping):
            continue
        if item.get("dataset_key") != dataset_key:
            continue
        return _sheet_name_or_none(item.get("sheet_name")), _bool_or_none(item.get("header_row"))
    return None, None


def _set_sheet_options(
    item: JsonObject, *, sheet_name: str | None, header_row: bool | None
) -> JsonObject:
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


def set_dataset_excel_options(
    manifest: JsonObject, *, dataset_key: str, sheet_name: str | None, header_row: bool | None
) -> JsonObject:
    datasets_obj = manifest.get("datasets")
    if not isinstance(datasets_obj, list):
        raise ValueError("manifest missing datasets[]")

    applied = False
    updated_datasets: list[JsonValue] = []
    for raw in datasets_obj:
        if isinstance(raw, dict) and raw.get("dataset_key") == dataset_key and not applied:
            updated_datasets.append(
                _set_sheet_options(raw, sheet_name=sheet_name, header_row=header_row)
            )
            applied = True
        else:
            updated_datasets.append(raw)
    if not applied:
        raise ValueError("dataset_key not found")

    out = dict(manifest)
    out["datasets"] = updated_datasets
    return cast(JsonObject, out)


def primary_dataset_excel_options(manifest: Mapping[str, object]) -> tuple[str | None, bool | None]:
    datasets = manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            if item.get("role") != "primary_dataset":
                continue
            return (
                _sheet_name_or_none(item.get("sheet_name")),
                _bool_or_none(item.get("header_row")),
            )

    primary = manifest.get("primary_dataset")
    if isinstance(primary, Mapping):
        return (
            _sheet_name_or_none(primary.get("sheet_name")),
            _bool_or_none(primary.get("header_row")),
        )
    return _sheet_name_or_none(manifest.get("primary_dataset_sheet_name")), _bool_or_none(
        manifest.get("primary_dataset_header_row")
    )


def set_primary_dataset_excel_options(
    manifest: JsonObject, *, sheet_name: str | None, header_row: bool | None
) -> JsonObject:
    datasets_obj = manifest.get("datasets")
    if isinstance(datasets_obj, list):
        updated_datasets: list[JsonValue] = []
        applied = False
        for raw in datasets_obj:
            if isinstance(raw, dict) and raw.get("role") == "primary_dataset" and not applied:
                updated_datasets.append(
                    _set_sheet_options(raw, sheet_name=sheet_name, header_row=header_row)
                )
                applied = True
            else:
                updated_datasets.append(raw)
        if not applied:
            return manifest
        out = dict(manifest)
        out["datasets"] = updated_datasets
        return cast(JsonObject, out)

    primary_obj = manifest.get("primary_dataset")
    if isinstance(primary_obj, dict):
        out = dict(manifest)
        out["primary_dataset"] = _set_sheet_options(
            primary_obj,
            sheet_name=sheet_name,
            header_row=header_row,
        )
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
    return cast(JsonObject, out)
