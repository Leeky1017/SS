from __future__ import annotations

import logging
from collections.abc import Mapping
from json import JSONDecodeError

from src.domain.dataset_preview import dataset_preview_with_options
from src.domain.inputs_manifest import primary_dataset_details, read_manifest_json
from src.domain.inputs_manifest_dataset_options import primary_dataset_excel_options
from src.domain.job_workspace_store import JobWorkspaceStore
from src.domain.models import Draft, Job, JobConfirmation
from src.domain.variable_corrections import (
    apply_variable_corrections_dict_values,
    apply_variable_corrections_text,
    apply_variable_corrections_to_draft,
)
from src.infra.input_exceptions import InputPathUnsafeError
from src.infra.plan_exceptions import ContractColumnNotFoundError
from src.utils.json_types import JsonValue

logger = logging.getLogger(__name__)


def apply_confirmation_effects(
    *, job: Job, confirmation: JobConfirmation
) -> tuple[Job, JobConfirmation]:
    corrections = confirmation.variable_corrections
    if len(corrections) == 0:
        return job, confirmation

    if job.requirement is not None:
        job.requirement = apply_variable_corrections_text(job.requirement, corrections)
    if confirmation.requirement is not None:
        confirmation = confirmation.model_copy(
            update={
                "requirement": apply_variable_corrections_text(
                    confirmation.requirement, corrections
                )
            }
        )
    if job.draft is not None:
        job.draft = apply_variable_corrections_to_draft(job.draft, corrections)
    if len(confirmation.default_overrides) > 0:
        confirmation = confirmation.model_copy(
            update={
                "default_overrides": apply_variable_corrections_dict_values(
                    confirmation.default_overrides, corrections
                )
            }
        )
    return job, confirmation


def analysis_spec_from_draft(*, job: Job) -> dict[str, JsonValue]:
    draft = job.draft
    if draft is None:
        return {}
    return {
        "outcome_var": draft.outcome_var,
        "treatment_var": draft.treatment_var,
        "controls": list(draft.controls),
        "default_overrides": dict(draft.default_overrides),
    }


def validate_contract_columns(*, workspace: JobWorkspaceStore, tenant_id: str, job: Job) -> None:
    if job.draft is None:
        return
    if job.inputs is None or job.inputs.manifest_rel_path is None:
        return
    manifest_rel_path = job.inputs.manifest_rel_path
    if manifest_rel_path.strip() == "":
        return

    try:
        manifest_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job.job_id,
            rel_path=manifest_rel_path,
        )
        manifest = read_manifest_json(manifest_path)
        dataset_rel_path, fmt, _original_name = primary_dataset_details(manifest)
        dataset_path = workspace.resolve_for_read(
            tenant_id=tenant_id,
            job_id=job.job_id,
            rel_path=dataset_rel_path,
        )
        sheet_name, header_row = primary_dataset_excel_options(manifest)
        preview = dataset_preview_with_options(
            path=dataset_path, fmt=fmt, rows=1, columns=300, sheet_name=sheet_name,
            header_row=header_row
        )
        names = _preview_column_names(preview=preview)
    except (FileNotFoundError, KeyError, OSError, JSONDecodeError, ValueError,
            InputPathUnsafeError) as e:
        logger.warning(
            "SS_CONTRACT_COLUMNS_PREVIEW_FAILED",
            extra={
                "tenant_id": tenant_id,
                "job_id": job.job_id,
                "rel_path": manifest_rel_path,
                "reason": str(e),
            },
        )
        return

    missing = _missing_contract_vars(draft=job.draft, columns=names)
    if len(missing) == 0:
        return
    logger.info(
        "SS_CONTRACT_COLUMNS_NOT_FOUND",
        extra={"tenant_id": tenant_id, "job_id": job.job_id, "missing": ",".join(missing)},
    )
    raise ContractColumnNotFoundError(missing=missing)


def _preview_column_names(*, preview: Mapping[str, object]) -> set[str]:
    columns = preview.get("columns", [])
    if not isinstance(columns, list):
        return set()
    names: set[str] = set()
    for item in columns:
        if not isinstance(item, Mapping):
            continue
        name = item.get("name")
        if isinstance(name, str) and name.strip() != "":
            names.add(name)
    return names


def _missing_contract_vars(*, draft: Draft, columns: set[str]) -> list[str]:
    missing: list[str] = []
    if (
        draft.outcome_var is not None
        and draft.outcome_var.strip() != ""
        and draft.outcome_var not in columns
    ):
        missing.append(draft.outcome_var)
    if (
        draft.treatment_var is not None
        and draft.treatment_var.strip() != ""
        and draft.treatment_var not in columns
    ):
        missing.append(draft.treatment_var)
    for item in draft.controls:
        if item.strip() != "" and item not in columns:
            missing.append(item)
    return sorted(set(missing))
