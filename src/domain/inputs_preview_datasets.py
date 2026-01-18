from __future__ import annotations

import logging
from collections.abc import Mapping
from typing import cast
from zipfile import BadZipFile

from src.domain.dataset_preview import excel_sheet_names
from src.domain.inputs_manifest import ROLE_OTHER, ROLE_PRIMARY_DATASET
from src.domain.inputs_manifest_dataset_options import primary_dataset_excel_options
from src.domain.job_workspace_store import JobWorkspaceStore
from src.infra.input_exceptions import InputPathUnsafeError
from src.utils.json_types import JsonObject

logger = logging.getLogger(__name__)


def _sheet_name_or_none(value: object) -> str | None:
    if not isinstance(value, str):
        return None
    cleaned = value.strip()
    return None if cleaned == "" else cleaned


def _bool_or_none(value: object) -> bool | None:
    if isinstance(value, bool):
        return value
    return None


def _dataset_excel_options(
    *, dataset: Mapping[str, object], manifest: Mapping[str, object]
) -> tuple[str | None, bool | None]:
    sheet_name = _sheet_name_or_none(dataset.get("sheet_name"))
    header_row = _bool_or_none(dataset.get("header_row"))
    if dataset.get("role") == ROLE_PRIMARY_DATASET and sheet_name is None and header_row is None:
        return primary_dataset_excel_options(manifest)
    return sheet_name, header_row


def _excel_sheet_names(
    *,
    tenant_id: str,
    job_id: str,
    manifest_rel_path: str,
    dataset_key: str,
    rel_path: str,
    workspace: JobWorkspaceStore,
) -> list[str]:
    try:
        dataset_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=rel_path,
        )
        return excel_sheet_names(path=dataset_path)
    except (
        BadZipFile,
        FileNotFoundError,
        ImportError,
        InputPathUnsafeError,
        OSError,
        ValueError,
    ) as exc:
        logger.warning(
            "SS_INPUT_PREVIEW_EXCEL_SHEET_NAMES_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "manifest_rel_path": manifest_rel_path,
                "dataset_key": dataset_key,
                "rel_path": rel_path,
                "reason": str(exc),
            },
        )
        return []


def datasets_preview_payload(
    *,
    tenant_id: str,
    job_id: str,
    manifest_rel_path: str,
    manifest: Mapping[str, object],
    workspace: JobWorkspaceStore,
) -> list[JsonObject]:
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list):
        return []

    out: list[JsonObject] = []
    for item in datasets:
        if not isinstance(item, Mapping):
            continue

        dataset_key = item.get("dataset_key")
        rel_path = item.get("rel_path")
        fmt = item.get("format")
        if (
            not isinstance(dataset_key, str)
            or dataset_key.strip() == ""
            or not isinstance(rel_path, str)
            or rel_path.strip() == ""
            or not isinstance(fmt, str)
            or fmt.strip() == ""
        ):
            continue
        role_obj = item.get("role")
        role = role_obj if isinstance(role_obj, str) and role_obj.strip() != "" else ROLE_OTHER
        original_name_obj = item.get("original_name")
        original_name = (
            original_name_obj
            if isinstance(original_name_obj, str) and original_name_obj.strip() != ""
            else rel_path
        )

        sheet_name, header_row = _dataset_excel_options(dataset=item, manifest=manifest)
        sheet_names = (
            _excel_sheet_names(
                tenant_id=tenant_id,
                job_id=job_id,
                manifest_rel_path=manifest_rel_path,
                dataset_key=dataset_key,
                rel_path=rel_path,
                workspace=workspace,
            )
            if fmt == "excel"
            else []
        )
        out.append(
            cast(
                JsonObject,
                {
                    "dataset_key": dataset_key,
                    "role": role,
                    "original_name": original_name,
                    "format": fmt,
                    "sheet_names": sheet_names,
                    "selected_sheet": sheet_name,
                    "header_row": header_row,
                },
            )
        )
    return out
