from __future__ import annotations

import logging
import shutil
from collections.abc import Mapping
from pathlib import Path
from typing import cast

from src.domain.composition_exec.refs import (
    ensure_safe_product_ref,
    parse_dataset_ref,
    safe_job_rel_resolve,
)
from src.domain.composition_exec.types import (
    MaterializedStepInputs,
    ResolvedBinding,
    ResolvedProduct,
)
from src.domain.models import PlanStep
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.infra.stata_run_support import RunDirs, write_json
from src.utils.json_types import JsonObject, JsonValue

logger = logging.getLogger(__name__)


def materialize_step_inputs(
    *,
    job_dir: Path,
    step: PlanStep,
    dirs: RunDirs,
    inputs_by_key: Mapping[str, str],
    products: Mapping[tuple[str, str], ResolvedProduct],
) -> MaterializedStepInputs:
    bindings = _raw_input_bindings(step=step)
    inputs_dir = dirs.run_dir / "inputs"
    inputs_dir.mkdir(parents=True, exist_ok=True)

    resolved_bindings: list[ResolvedBinding] = []
    datasets: list[JsonObject] = []
    for role, dataset_ref in bindings.items():
        resolved = _resolve_binding(
            job_dir=job_dir,
            step_id=step.step_id,
            role=role,
            dataset_ref=dataset_ref,
            inputs_by_key=inputs_by_key,
            products=products,
        )
        _copy_binding_to_inputs_dir(
            step_id=step.step_id,
            source=resolved.source_path,
            dest=inputs_dir / resolved.dest_filename,
        )
        resolved_bindings.append(resolved.binding)
        datasets.append(
            cast(
                JsonObject,
                {
                    "dataset_key": resolved.binding.dataset_key,
                    "role": resolved.binding.role,
                    "rel_path": f"inputs/{resolved.binding.dest_filename}",
                },
            )
        )

    manifest: JsonObject = {"schema_version": 2, "datasets": cast(JsonValue, datasets)}
    write_json(inputs_dir / "manifest.json", manifest)
    return MaterializedStepInputs(
        inputs_dir=inputs_dir,
        bindings=tuple(resolved_bindings),
        manifest=manifest,
    )


def _raw_input_bindings(*, step: PlanStep) -> Mapping[str, str]:
    raw = step.params.get("input_bindings")
    if not isinstance(raw, Mapping) or len(raw) == 0:
        raise PlanCompositionInvalidError(reason="missing_input_bindings", step_id=step.step_id)
    out: dict[str, str] = {}
    for role_obj, ref_obj in raw.items():
        role = role_obj if isinstance(role_obj, str) else ""
        dataset_ref = ref_obj if isinstance(ref_obj, str) else ""
        if role.strip() == "":
            raise PlanCompositionInvalidError(
                reason="input_binding_role_empty",
                step_id=step.step_id,
            )
        if dataset_ref.strip() == "":
            raise PlanCompositionInvalidError(reason="dataset_ref_empty", step_id=step.step_id)
        out[role] = dataset_ref
    if len(out) == 0:
        raise PlanCompositionInvalidError(reason="missing_input_bindings", step_id=step.step_id)
    return out


class _ResolvedBindingSource:
    def __init__(self, *, binding: ResolvedBinding, source_path: Path, dest_filename: str) -> None:
        self.binding = binding
        self.source_path = source_path
        self.dest_filename = dest_filename


def _resolve_binding(
    *,
    job_dir: Path,
    step_id: str,
    role: str,
    dataset_ref: str,
    inputs_by_key: Mapping[str, str],
    products: Mapping[tuple[str, str], ResolvedProduct],
) -> _ResolvedBindingSource:
    kind, a, b = parse_dataset_ref(step_id=step_id, dataset_ref=dataset_ref)
    if kind == "input":
        return _resolve_input_binding(
            job_dir=job_dir,
            step_id=step_id,
            role=role,
            dataset_ref=dataset_ref,
            dataset_key=a,
            inputs_by_key=inputs_by_key,
        )

    assert b is not None
    return _resolve_product_binding(
        job_dir=job_dir,
        step_id=step_id,
        role=role,
        dataset_ref=dataset_ref,
        producer_step_id=a,
        product_id=b,
        products=products,
    )


def _resolve_input_binding(
    *,
    job_dir: Path,
    step_id: str,
    role: str,
    dataset_ref: str,
    dataset_key: str,
    inputs_by_key: Mapping[str, str],
) -> _ResolvedBindingSource:
    rel_path = inputs_by_key.get(dataset_key, "")
    if rel_path == "":
        raise PlanCompositionInvalidError(
            reason="unknown_input_dataset",
            step_id=step_id,
            dataset_ref=dataset_ref,
        )
    source = safe_job_rel_resolve(job_dir=job_dir, rel_path=rel_path, step_id=step_id)
    dest_filename = Path(rel_path).name
    binding = ResolvedBinding(
        role=role,
        dataset_ref=dataset_ref,
        source_rel_path=rel_path,
        dest_filename=dest_filename,
        dataset_key=dataset_key,
    )
    return _ResolvedBindingSource(binding=binding, source_path=source, dest_filename=dest_filename)


def _resolve_product_binding(
    *,
    job_dir: Path,
    step_id: str,
    role: str,
    dataset_ref: str,
    producer_step_id: str,
    product_id: str,
    products: Mapping[tuple[str, str], ResolvedProduct],
) -> _ResolvedBindingSource:
    ensure_safe_product_ref(
        step_id=producer_step_id,
        product_id=product_id,
        consumer_step_id=step_id,
    )
    product = products.get((producer_step_id, product_id))
    if product is None:
        raise PlanCompositionInvalidError(
            reason="unknown_product_ref",
            step_id=step_id,
            dataset_ref=dataset_ref,
        )
    source = safe_job_rel_resolve(
        job_dir=job_dir,
        rel_path=product.artifact_rel_path,
        step_id=step_id,
    )
    suffix = Path(product.artifact_rel_path).suffix
    dest_filename = f"{producer_step_id}__{product_id}{suffix}"
    binding = ResolvedBinding(
        role=role,
        dataset_ref=dataset_ref,
        source_rel_path=product.artifact_rel_path,
        dest_filename=dest_filename,
        dataset_key=f"prod_{producer_step_id}_{product_id}",
    )
    return _ResolvedBindingSource(binding=binding, source_path=source, dest_filename=dest_filename)


def _copy_binding_to_inputs_dir(*, step_id: str, source: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        shutil.copy2(source, dest)
    except FileNotFoundError as e:
        raise PlanCompositionInvalidError(reason="binding_source_missing", step_id=step_id) from e
    except OSError as e:
        logger.warning(
            "SS_COMPOSITION_INPUT_COPY_FAILED",
            extra={"step_id": step_id, "src": str(source), "dst": str(dest)},
        )
        raise PlanCompositionInvalidError(reason="binding_copy_failed", step_id=step_id) from e
