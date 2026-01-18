from __future__ import annotations

import logging
from json import JSONDecodeError
from typing import cast

from src.domain.dataset_preview import dataset_preview_with_options
from src.domain.inputs_manifest import primary_dataset_details, read_manifest_json
from src.domain.inputs_manifest_dataset_options import primary_dataset_excel_options
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import DraftDataSource, DraftVariableType
from src.infra.input_exceptions import InputPathUnsafeError
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


def _load_inputs_manifest(
    *,
    tenant_id: str,
    job_id: str,
    store: JobStore,
    workspace: JobWorkspaceStore,
) -> tuple[str, dict[str, object]] | None:
    job = store.load(tenant_id=tenant_id, job_id=job_id)
    manifest_rel_path = None if job.inputs is None else job.inputs.manifest_rel_path
    if manifest_rel_path is None or manifest_rel_path.strip() == "":
        return None
    try:
        manifest_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=manifest_rel_path,
        )
        manifest = read_manifest_json(manifest_path)
    except (FileNotFoundError, OSError, JSONDecodeError, InputPathUnsafeError, ValueError) as e:
        logger.warning(
            "SS_DRAFT_PREVIEW_INPUTS_MANIFEST_READ_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "rel_path": manifest_rel_path,
                "reason": str(e),
            },
        )
        return None
    return manifest_rel_path, cast(dict[str, object], manifest)


def draft_data_sources(
    *,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    store: JobStore,
    workspace: JobWorkspaceStore,
) -> list[DraftDataSource]:
    loaded = _load_inputs_manifest(
        tenant_id=tenant_id,
        job_id=job_id,
        store=store,
        workspace=workspace,
    )
    if loaded is None:
        return []
    _manifest_rel_path, manifest = loaded
    datasets = manifest.get("datasets")
    if not isinstance(datasets, list):
        return []
    sources: list[DraftDataSource] = []
    for item in datasets:
        if not isinstance(item, dict):
            continue
        dataset_key = item.get("dataset_key")
        role = item.get("role")
        original_name = item.get("original_name")
        fmt = item.get("format")
        if (
            isinstance(dataset_key, str)
            and isinstance(role, str)
            and isinstance(original_name, str)
            and isinstance(fmt, str)
        ):
            sources.append(
                DraftDataSource(
                    dataset_key=dataset_key,
                    role=role,
                    original_name=original_name,
                    format=fmt,
                )
            )
    return sources


def _primary_columns_payload(
    *,
    tenant_id: str,
    job_id: str,
    manifest_rel_path: str,
    manifest: dict[str, object],
    workspace: JobWorkspaceStore,
) -> list[dict[str, object]] | None:
    try:
        dataset_rel_path, fmt, _original_name = primary_dataset_details(manifest)
        dataset_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=dataset_rel_path,
        )
        sheet_name, header_row = primary_dataset_excel_options(manifest)
        preview = dataset_preview_with_options(
            path=dataset_path,
            fmt=fmt,
            rows=1,
            columns=300,
            sheet_name=sheet_name,
            header_row=header_row,
        )
    except (FileNotFoundError, KeyError, OSError, ValueError) as e:
        logger.warning(
            "SS_DRAFT_PREVIEW_DATASET_PREVIEW_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "rel_path": manifest_rel_path,
                "reason": str(e),
            },
        )
        return None
    payload = preview.get("columns")
    if not isinstance(payload, list):
        return None
    return cast(list[dict[str, object]], payload)


def primary_dataset_columns(
    *,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    store: JobStore,
    workspace: JobWorkspaceStore,
) -> tuple[list[str], list[DraftVariableType]]:
    loaded = _load_inputs_manifest(
        tenant_id=tenant_id,
        job_id=job_id,
        store=store,
        workspace=workspace,
    )
    if loaded is None:
        return [], []
    manifest_rel_path, manifest = loaded
    payload = _primary_columns_payload(
        tenant_id=tenant_id,
        job_id=job_id,
        manifest_rel_path=manifest_rel_path,
        manifest=manifest,
        workspace=workspace,
    )
    if payload is None:
        return [], []
    candidates: list[str] = []
    types: list[DraftVariableType] = []
    for item in payload:
        name = item.get("name")
        inferred_type = item.get("inferred_type")
        if not isinstance(name, str) or name.strip() == "":
            continue
        candidates.append(name)
        if isinstance(inferred_type, str) and inferred_type.strip() != "":
            types.append(DraftVariableType(name=name, inferred_type=inferred_type))
    return candidates[:300], types[:300]
