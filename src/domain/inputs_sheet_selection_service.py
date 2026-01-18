from __future__ import annotations

import logging
from json import JSONDecodeError
from pathlib import Path
from typing import cast
from zipfile import BadZipFile

from src.domain.dataset_preview import dataset_preview_with_options, excel_sheet_names
from src.domain.inputs_manifest import (
    MANIFEST_REL_PATH,
    primary_dataset_details,
    read_manifest_json,
)
from src.domain.inputs_manifest_dataset_options import (
    dataset_details,
    set_dataset_excel_options,
    set_primary_dataset_excel_options,
)
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import (
    InputDatasetNotFoundError,
    InputExcelSheetNotFoundError,
    InputExcelSheetSelectionUnsupportedError,
    InputParseFailedError,
    InputPathUnsafeError,
    InputStorageFailedError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


def _clean_sheet_name(sheet_name: str) -> str:
    cleaned = sheet_name.strip()
    if cleaned == "":
        raise InputExcelSheetNotFoundError(sheet_name=sheet_name, available=[])
    return cleaned


class InputsSheetSelectionService:
    def __init__(self, *, store: JobStore, workspace: JobWorkspaceStore):
        self._store = store
        self._workspace = workspace

    def _load_manifest(self, *, tenant_id: str, job_id: str) -> tuple[str, JsonObject]:
        job = self._store.load(tenant_id=tenant_id, job_id=job_id)
        manifest_rel_path = None if job.inputs is None else job.inputs.manifest_rel_path
        if manifest_rel_path is None or manifest_rel_path.strip() == "":
            raise InputParseFailedError(filename=MANIFEST_REL_PATH, detail="manifest not set")

        try:
            manifest_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=manifest_rel_path,
            )
            manifest = read_manifest_json(manifest_path)
        except (
            FileNotFoundError,
            OSError,
            JSONDecodeError,
            InputPathUnsafeError,
            ValueError,
        ) as exc:
            logger.warning(
                "SS_INPUT_SHEET_MANIFEST_READ_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": manifest_rel_path},
            )
            raise InputParseFailedError(
                filename=manifest_rel_path,
                detail="manifest invalid",
            ) from exc

        return manifest_rel_path, manifest

    def _resolve_excel_dataset(
        self,
        *,
        tenant_id: str,
        job_id: str,
        dataset_rel_path: str,
        fmt: str,
        original_name: str,
    ) -> tuple[Path, list[str]]:
        if fmt != "excel":
            raise InputExcelSheetSelectionUnsupportedError(format=fmt)
        try:
            dataset_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=dataset_rel_path,
            )
            available = excel_sheet_names(path=dataset_path)
        except (FileNotFoundError, OSError, ImportError, ValueError, BadZipFile) as exc:
            raise InputParseFailedError(
                filename=original_name,
                detail="excel not readable",
            ) from exc
        return dataset_path, available

    def _infer_header_row(
        self,
        *,
        dataset_path: Path,
        fmt: str,
        original_name: str,
        sheet_name: str,
    ) -> bool | None:
        try:
            preview = dataset_preview_with_options(
                path=dataset_path,
                fmt=fmt,
                rows=1,
                columns=1,
                sheet_name=sheet_name,
                header_row=None,
            )
        except (BadZipFile, ImportError, KeyError, OSError, UnicodeDecodeError, ValueError) as exc:
            raise InputParseFailedError(
                filename=original_name,
                detail="excel not readable",
            ) from exc
        inferred = preview.get("header_row")
        return inferred if isinstance(inferred, bool) else None

    def _write_manifest(
        self, *, tenant_id: str, job_id: str, manifest_rel_path: str, manifest: JsonObject
    ) -> None:
        try:
            self._store.write_artifact_json(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=manifest_rel_path,
                payload=manifest,
            )
        except JobStoreIOError as exc:
            logger.warning(
                "SS_INPUT_SHEET_MANIFEST_WRITE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": manifest_rel_path,
                    "error_code": exc.error_code,
                },
            )
            raise InputStorageFailedError(job_id=job_id, rel_path=manifest_rel_path) from exc

    def select_primary_excel_sheet(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        sheet_name: str,
    ) -> JsonObject:
        cleaned = _clean_sheet_name(sheet_name)
        manifest_rel_path, manifest = self._load_manifest(tenant_id=tenant_id, job_id=job_id)
        dataset_rel_path, fmt, original_name = primary_dataset_details(manifest)
        dataset_path, available = self._resolve_excel_dataset(
            tenant_id=tenant_id,
            job_id=job_id,
            dataset_rel_path=dataset_rel_path,
            fmt=fmt,
            original_name=original_name,
        )
        if cleaned not in available:
            raise InputExcelSheetNotFoundError(sheet_name=cleaned, available=available)
        header_row = self._infer_header_row(
            dataset_path=dataset_path,
            fmt=fmt,
            original_name=original_name,
            sheet_name=cleaned,
        )
        updated = set_primary_dataset_excel_options(
            manifest,
            sheet_name=cleaned,
            header_row=header_row,
        )
        self._write_manifest(
            tenant_id=tenant_id,
            job_id=job_id,
            manifest_rel_path=manifest_rel_path,
            manifest=updated,
        )
        logger.info(
            "SS_INPUT_PRIMARY_EXCEL_SHEET_SELECTED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "sheet_name": cleaned,
                "header_row": header_row,
            },
        )
        return cast(
            JsonObject,
            {
                "job_id": job_id,
                "selected_sheet": cleaned,
                "header_row": header_row,
                "sheet_names": available,
            },
        )

    def select_dataset_excel_sheet(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        dataset_key: str,
        sheet_name: str,
    ) -> JsonObject:
        cleaned = _clean_sheet_name(sheet_name)
        target_key = dataset_key.strip()
        if target_key == "":
            raise InputDatasetNotFoundError(dataset_key=dataset_key)

        manifest_rel_path, manifest = self._load_manifest(tenant_id=tenant_id, job_id=job_id)
        try:
            dataset_rel_path, fmt, original_name, role = dataset_details(
                manifest,
                dataset_key=target_key,
            )
        except ValueError as exc:
            raise InputDatasetNotFoundError(dataset_key=dataset_key) from exc

        dataset_path, available = self._resolve_excel_dataset(
            tenant_id=tenant_id,
            job_id=job_id,
            dataset_rel_path=dataset_rel_path,
            fmt=fmt,
            original_name=original_name,
        )
        if cleaned not in available:
            raise InputExcelSheetNotFoundError(sheet_name=cleaned, available=available)
        header_row = self._infer_header_row(
            dataset_path=dataset_path,
            fmt=fmt,
            original_name=original_name,
            sheet_name=cleaned,
        )

        updated = set_dataset_excel_options(
            manifest,
            dataset_key=target_key,
            sheet_name=cleaned,
            header_row=header_row,
        )
        self._write_manifest(
            tenant_id=tenant_id,
            job_id=job_id,
            manifest_rel_path=manifest_rel_path,
            manifest=updated,
        )
        logger.info(
            "SS_INPUT_DATASET_EXCEL_SHEET_SELECTED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "dataset_key": target_key,
                "role": role,
                "sheet_name": cleaned,
                "header_row": header_row,
            },
        )
        return cast(
            JsonObject,
            {
                "job_id": job_id,
                "dataset_key": target_key,
                "role": role,
                "selected_sheet": cleaned,
                "header_row": header_row,
                "sheet_names": available,
            },
        )
