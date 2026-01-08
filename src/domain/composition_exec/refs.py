from __future__ import annotations

from collections.abc import Mapping
from pathlib import Path

from src.domain.models import is_safe_job_rel_path
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.utils.job_workspace import is_safe_path_segment


def parse_dataset_ref(*, step_id: str, dataset_ref: str) -> tuple[str, str, str | None]:
    if dataset_ref.strip() == "":
        raise PlanCompositionInvalidError(reason="dataset_ref_empty", step_id=step_id)
    parts = dataset_ref.split(":")
    if len(parts) == 2 and parts[0] == "input":
        key = parts[1].strip()
        if key == "":
            raise PlanCompositionInvalidError(
                reason="dataset_ref_invalid",
                step_id=step_id,
                dataset_ref=dataset_ref,
            )
        return "input", key, None
    if len(parts) == 3 and parts[0] == "prod":
        producer_step_id = parts[1].strip()
        product_id = parts[2].strip()
        if producer_step_id == "" or product_id == "":
            raise PlanCompositionInvalidError(
                reason="dataset_ref_invalid",
                step_id=step_id,
                dataset_ref=dataset_ref,
            )
        return "prod", producer_step_id, product_id
    raise PlanCompositionInvalidError(
        reason="dataset_ref_invalid",
        step_id=step_id,
        dataset_ref=dataset_ref,
    )


def inputs_by_key(*, inputs_manifest: Mapping[str, object]) -> dict[str, str]:
    mapping: dict[str, str] = {}
    datasets = inputs_manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            dataset_key = item.get("dataset_key")
            rel_path = item.get("rel_path")
            if not isinstance(dataset_key, str) or not isinstance(rel_path, str):
                continue
            key = dataset_key.strip()
            path = rel_path.strip()
            if key != "" and path != "":
                mapping[key] = path

    primary = inputs_manifest.get("primary_dataset")
    if isinstance(primary, Mapping):
        rel_path = primary.get("rel_path")
        if isinstance(rel_path, str) and rel_path.strip() != "":
            mapping.setdefault("primary", rel_path.strip())
    else:
        rel_path = inputs_manifest.get("primary_dataset_rel_path")
        if isinstance(rel_path, str) and rel_path.strip() != "":
            mapping.setdefault("primary", rel_path.strip())
    return mapping


def safe_job_rel_resolve(*, job_dir: Path, rel_path: str, step_id: str) -> Path:
    if rel_path.strip() == "" or not is_safe_job_rel_path(rel_path):
        raise PlanCompositionInvalidError(reason="rel_path_unsafe", step_id=step_id)
    base = job_dir.resolve(strict=False)
    path = (job_dir / rel_path).resolve(strict=False)
    if not path.is_relative_to(base):
        raise PlanCompositionInvalidError(reason="rel_path_escape", step_id=step_id)
    return path


def ensure_safe_product_ref(*, step_id: str, product_id: str, consumer_step_id: str) -> None:
    if not is_safe_path_segment(step_id) or not is_safe_path_segment(product_id):
        raise PlanCompositionInvalidError(reason="unsafe_product_ref", step_id=consumer_step_id)
