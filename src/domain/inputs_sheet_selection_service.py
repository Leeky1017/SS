from __future__ import annotations

import logging
from json import JSONDecodeError
from typing import cast

from src.domain.dataset_preview import dataset_preview_with_options, excel_sheet_names
from src.domain.inputs_manifest import (
    MANIFEST_REL_PATH,
    primary_dataset_details,
    read_manifest_json,
    set_primary_dataset_excel_options,
)
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.infra.exceptions import JobStoreIOError
from src.infra.input_exceptions import (
    InputExcelSheetNotFoundError,
    InputExcelSheetSelectionUnsupportedError,
    InputParseFailedError,
    InputPathUnsafeError,
    InputStorageFailedError,
)
from src.utils.json_types import JsonObject
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


class InputsSheetSelectionService:
    def __init__(self, *, store: JobStore, workspace: JobWorkspaceStore):
        self._store = store
        self._workspace = workspace

    def select_primary_excel_sheet(
        self,
        *,
        tenant_id: str = DEFAULT_TENANT_ID,
        job_id: str,
        sheet_name: str,
    ) -> JsonObject:
        cleaned = sheet_name.strip()
        if cleaned == "":
            raise InputExcelSheetNotFoundError(sheet_name=sheet_name, available=[])

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
        except (FileNotFoundError, OSError, JSONDecodeError, InputPathUnsafeError, ValueError) as e:
            logger.warning(
                "SS_INPUT_SHEET_MANIFEST_READ_FAILED",
                extra={"tenant_id": tenant_id, "job_id": job_id, "rel_path": manifest_rel_path},
            )
            raise InputParseFailedError(
                filename=manifest_rel_path,
                detail="manifest invalid",
            ) from e

        dataset_rel_path, fmt, original_name = primary_dataset_details(manifest)
        if fmt != "excel":
            raise InputExcelSheetSelectionUnsupportedError(format=fmt)
        try:
            dataset_path = self._workspace.resolve_for_read(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=dataset_rel_path,
            )
            available = excel_sheet_names(path=dataset_path)
        except (FileNotFoundError, OSError, ImportError, ValueError) as e:
            raise InputParseFailedError(filename=original_name, detail="excel not readable") from e

        if cleaned not in available:
            raise InputExcelSheetNotFoundError(sheet_name=cleaned, available=available)

        preview = dataset_preview_with_options(
            path=dataset_path,
            fmt=fmt,
            rows=1,
            columns=1,
            sheet_name=cleaned,
            header_row=None,
        )
        inferred = preview.get("header_row")
        header_row = inferred if isinstance(inferred, bool) else None

        updated = set_primary_dataset_excel_options(
            cast(JsonObject, manifest),
            sheet_name=cleaned,
            header_row=header_row,
        )
        try:
            self._store.write_artifact_json(
                tenant_id=tenant_id,
                job_id=job_id,
                rel_path=manifest_rel_path,
                payload=updated,
            )
        except JobStoreIOError as e:
            logger.warning(
                "SS_INPUT_SHEET_MANIFEST_WRITE_FAILED",
                extra={
                    "tenant_id": tenant_id,
                    "job_id": job_id,
                    "rel_path": manifest_rel_path,
                    "error_code": e.error_code,
                },
            )
            raise InputStorageFailedError(job_id=job_id, rel_path=manifest_rel_path) from e

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
