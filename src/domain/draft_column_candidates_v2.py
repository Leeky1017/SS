from __future__ import annotations

import logging
from typing import Sequence, cast

from src.domain.dataset_preview import dataset_preview_with_options
from src.domain.draft_column_candidate_models import DraftColumnCandidateV2
from src.domain.draft_inputs_introspection import _load_inputs_manifest
from src.domain.inputs_manifest import ROLE_PRIMARY_DATASET
from src.domain.inputs_manifest_dataset_options import primary_dataset_excel_options
from src.domain.job_store import JobStore
from src.domain.job_workspace_store import JobWorkspaceStore
from src.infra.input_exceptions import InputPathUnsafeError
from src.utils.tenancy import DEFAULT_TENANT_ID

logger = logging.getLogger(__name__)


def _datasets_list(manifest: dict[str, object]) -> list[dict[str, object]]:
    raw = manifest.get("datasets")
    if not isinstance(raw, list):
        return []
    return [item for item in raw if isinstance(item, dict)]


def _dataset_excel_options(item: dict[str, object]) -> tuple[str | None, bool | None]:
    sheet_name = item.get("sheet_name")
    header_row = item.get("header_row")
    sheet = sheet_name.strip() if isinstance(sheet_name, str) else ""
    return (None if sheet == "" else sheet, header_row if isinstance(header_row, bool) else None)


def _dataset_columns_payload(
    *,
    tenant_id: str,
    job_id: str,
    manifest_rel_path: str,
    item: dict[str, object],
    workspace: JobWorkspaceStore,
    manifest: dict[str, object],
) -> list[dict[str, object]] | None:
    rel_path = item.get("rel_path")
    try:
        fmt = item.get("format")
        if not isinstance(rel_path, str) or rel_path.strip() == "":
            raise KeyError("datasets[].rel_path missing")
        if not isinstance(fmt, str) or fmt.strip() == "":
            raise KeyError("datasets[].format missing")
        dataset_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job_id,
            rel_path=rel_path,
        )
        sheet_name, header_row = _dataset_excel_options(item)
        if item.get("role") == ROLE_PRIMARY_DATASET and sheet_name is None and header_row is None:
            sheet_name, header_row = primary_dataset_excel_options(manifest)
        preview = dataset_preview_with_options(
            path=dataset_path,
            fmt=fmt,
            rows=1,
            columns=300,
            sheet_name=sheet_name,
            header_row=header_row,
        )
    except (FileNotFoundError, KeyError, OSError, ValueError, InputPathUnsafeError) as e:
        logger.warning(
            "SS_DRAFT_PREVIEW_DATASET_PREVIEW_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job_id,
                "manifest_rel_path": manifest_rel_path,
                "rel_path": rel_path if isinstance(rel_path, str) else "",
                "reason": str(e),
            },
        )
        return None
    payload = preview.get("columns")
    if not isinstance(payload, list):
        return None
    return cast(list[dict[str, object]], payload)


def _primary_candidate_v2_items(
    datasets: list[dict[str, object]],
    primary_candidates: Sequence[str],
) -> list[DraftColumnCandidateV2]:
    primary = next((d for d in datasets if d.get("role") == ROLE_PRIMARY_DATASET), None)
    primary_dataset_key = primary.get("dataset_key") if isinstance(primary, dict) else None
    primary_role = primary.get("role") if isinstance(primary, dict) else None
    if (
        not isinstance(primary_dataset_key, str)
        or primary_dataset_key.strip() == ""
        or not isinstance(primary_role, str)
        or primary_role.strip() == ""
    ):
        return []
    out: list[DraftColumnCandidateV2] = []
    for name in primary_candidates[:300]:
        if isinstance(name, str) and name.strip() != "":
            out.append(
                DraftColumnCandidateV2(
                    dataset_key=primary_dataset_key,
                    role=primary_role,
                    name=name,
                )
            )
    return out


def _append_non_primary_candidate_v2_items(
    *,
    tenant_id: str,
    job_id: str,
    manifest_rel_path: str,
    manifest: dict[str, object],
    datasets: list[dict[str, object]],
    workspace: JobWorkspaceStore,
    out: list[DraftColumnCandidateV2],
    limit: int,
) -> None:
    for item in datasets:
        if item.get("role") == ROLE_PRIMARY_DATASET:
            continue
        dataset_key = item.get("dataset_key")
        role = item.get("role")
        if not isinstance(dataset_key, str) or dataset_key.strip() == "":
            continue
        if not isinstance(role, str) or role.strip() == "":
            continue

        payload = _dataset_columns_payload(
            tenant_id=tenant_id,
            job_id=job_id,
            manifest_rel_path=manifest_rel_path,
            item=item,
            workspace=workspace,
            manifest=manifest,
        )
        if payload is None:
            continue
        for col in payload[:300]:
            name = col.get("name")
            if isinstance(name, str) and name.strip() != "":
                out.append(DraftColumnCandidateV2(dataset_key=dataset_key, role=role, name=name))
            if len(out) >= limit:
                return


def column_candidates_v2(
    *,
    tenant_id: str = DEFAULT_TENANT_ID,
    job_id: str,
    store: JobStore,
    workspace: JobWorkspaceStore,
    primary_candidates: Sequence[str],
) -> list[DraftColumnCandidateV2]:
    loaded = _load_inputs_manifest(
        tenant_id=tenant_id,
        job_id=job_id,
        store=store,
        workspace=workspace,
    )
    if loaded is None:
        return []
    manifest_rel_path, manifest = loaded
    datasets = _datasets_list(manifest)
    if len(datasets) == 0:
        return []

    out = _primary_candidate_v2_items(datasets, primary_candidates)
    _append_non_primary_candidate_v2_items(
        tenant_id=tenant_id,
        job_id=job_id,
        manifest_rel_path=manifest_rel_path,
        manifest=manifest,
        datasets=datasets,
        workspace=workspace,
        out=out,
        limit=900,
    )
    return out
