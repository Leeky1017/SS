from __future__ import annotations

import shutil
from collections.abc import Mapping
from dataclasses import dataclass
from pathlib import Path

from pydantic import ValidationError

from src.domain.composition_exec.conditional import conditional_decision_or_none
from src.domain.composition_exec.refs import parse_dataset_ref, safe_job_rel_resolve
from src.domain.composition_exec.types import ResolvedBinding, ResolvedProduct
from src.domain.composition_plan import PlanProduct, ProductKind
from src.domain.csv_merge import CSVJoinError, append_csv, merge_csv
from src.domain.models import ArtifactKind, ArtifactRef, PlanStep
from src.infra.plan_exceptions import PlanCompositionInvalidError
from src.infra.stata_run_support import RunDirs, job_rel_path, write_text
from src.utils.job_workspace import is_safe_path_segment
from src.utils.json_types import JsonObject


def create_products_and_decisions(
    *,
    job_dir: Path,
    step: PlanStep,
    dirs: RunDirs,
    bindings: tuple[ResolvedBinding, ...],
    inputs_by_key: Mapping[str, str],
    runner_artifacts: tuple[ArtifactRef, ...],
) -> tuple[tuple[ResolvedProduct, ...], tuple[JsonObject, ...]]:
    products = _products_from_step(step=step)
    decisions: list[JsonObject] = []
    conditional = conditional_decision_or_none(step=step)
    if conditional is not None:
        decisions.append(conditional)
    if len(products) == 0:
        return tuple(), tuple(decisions)

    written: list[ResolvedProduct] = []
    for product in products:
        path = _product_artifact_path(dirs=dirs, product_id=product.product_id, kind=product.kind)
        rel = job_rel_path(job_dir=job_dir, path=path)
        if product.kind == ProductKind.DATASET:
            decision = _write_dataset_product(
                job_dir=job_dir,
                step=step,
                inputs_by_key=inputs_by_key,
                bindings=bindings,
                path=path,
            )
            if decision is not None:
                decisions.append(decision)
        elif product.kind == ProductKind.TABLE:
            _copy_export_table_as_product(
                job_dir=job_dir,
                step_id=step.step_id,
                runner_artifacts=runner_artifacts,
                path=path,
            )
        else:
            write_text(path, f'{{"kind": "{product.kind.value}"}}\\n')
        written.append(
            ResolvedProduct(
                step_id=step.step_id,
                product_id=product.product_id,
                kind=product.kind,
                artifact_rel_path=rel,
            )
        )
    return tuple(written), tuple(decisions)


def _products_from_step(*, step: PlanStep) -> tuple[PlanProduct, ...]:
    raw = step.params.get("products")
    if raw is None:
        return tuple()
    if not isinstance(raw, list):
        raise PlanCompositionInvalidError(reason="products_invalid", step_id=step.step_id)
    out: list[PlanProduct] = []
    for item in raw:
        try:
            out.append(PlanProduct.model_validate(item))
        except ValidationError as e:
            raise PlanCompositionInvalidError(
                reason="products_invalid",
                step_id=step.step_id,
            ) from e
    for product in out:
        if not is_safe_path_segment(product.product_id):
            raise PlanCompositionInvalidError(reason="unsafe_product_id", step_id=step.step_id)
    return tuple(out)


@dataclass(frozen=True)
class _MergeConfig:
    operation: str
    keys: tuple[str, ...]


def _merge_config(*, step: PlanStep) -> _MergeConfig | None:
    raw = step.params.get("merge")
    if not isinstance(raw, Mapping):
        return None
    operation = raw.get("operation")
    op = operation if isinstance(operation, str) else ""
    if op not in {"merge", "append"}:
        return None
    keys = raw.get("keys")
    if op == "append":
        parsed = _keys_or_empty(value=keys)
        return _MergeConfig(operation=op, keys=parsed)
    if not isinstance(keys, list) or len(keys) == 0:
        raise PlanCompositionInvalidError(reason="merge_keys_missing", step_id=step.step_id)
    parsed = tuple(k.strip() for k in keys if isinstance(k, str) and k.strip() != "")
    if len(parsed) == 0:
        raise PlanCompositionInvalidError(reason="merge_keys_missing", step_id=step.step_id)
    return _MergeConfig(operation=op, keys=parsed)


def _write_dataset_product(
    *,
    job_dir: Path,
    step: PlanStep,
    inputs_by_key: Mapping[str, str],
    bindings: tuple[ResolvedBinding, ...],
    path: Path,
) -> JsonObject | None:
    merge = _merge_config(step=step)
    if merge is None:
        _copy_primary_binding_as_product(
            job_dir=job_dir,
            step_id=step.step_id,
            bindings=bindings,
            path=path,
        )
        return None
    primary_path, secondary_path = _merge_input_paths(
        job_dir=job_dir,
        step=step,
        inputs_by_key=inputs_by_key,
        bindings=bindings,
    )
    try:
        if merge.operation == "append":
            output, stats = append_csv(primary_path=primary_path, secondary_path=secondary_path)
        else:
            output, stats = merge_csv(
                primary_path=primary_path,
                secondary_path=secondary_path,
                keys=merge.keys,
            )
    except CSVJoinError as e:
        raise PlanCompositionInvalidError(reason=e.reason, step_id=step.step_id) from e
    write_text(path, output)
    return {
        "type": merge.operation,
        "step_id": step.step_id,
        "keys": list(merge.keys),
        "stats": stats,
    }


def _merge_input_paths(
    *,
    job_dir: Path,
    step: PlanStep,
    inputs_by_key: Mapping[str, str],
    bindings: tuple[ResolvedBinding, ...],
) -> tuple[Path, Path]:
    primary_ref = _binding_ref(bindings=bindings, role="primary_dataset", step_id=step.step_id)
    secondary_ref = _binding_ref(bindings=bindings, role="secondary_dataset", step_id=step.step_id)
    kind_p, primary_key, _ = parse_dataset_ref(step_id=step.step_id, dataset_ref=primary_ref)
    kind_s, secondary_key, _ = parse_dataset_ref(step_id=step.step_id, dataset_ref=secondary_ref)
    if kind_p != "input" or kind_s != "input":
        raise PlanCompositionInvalidError(reason="merge_requires_input_refs", step_id=step.step_id)
    primary_rel = inputs_by_key.get(primary_key, "")
    secondary_rel = inputs_by_key.get(secondary_key, "")
    if primary_rel == "" or secondary_rel == "":
        raise PlanCompositionInvalidError(reason="merge_bindings_missing", step_id=step.step_id)
    return (
        safe_job_rel_resolve(job_dir=job_dir, rel_path=primary_rel, step_id=step.step_id),
        safe_job_rel_resolve(job_dir=job_dir, rel_path=secondary_rel, step_id=step.step_id),
    )


def _keys_or_empty(*, value: object) -> tuple[str, ...]:
    if not isinstance(value, list):
        return tuple()
    parsed: list[str] = []
    for item in value:
        if isinstance(item, str) and item.strip() != "":
            parsed.append(item.strip())
    return tuple(parsed)


def _binding_ref(*, bindings: tuple[ResolvedBinding, ...], role: str, step_id: str) -> str:
    for binding in bindings:
        if binding.role == role:
            return binding.dataset_ref
    raise PlanCompositionInvalidError(reason="merge_bindings_missing", step_id=step_id)


def _copy_export_table_as_product(
    *,
    job_dir: Path,
    step_id: str,
    runner_artifacts: tuple[ArtifactRef, ...],
    path: Path,
) -> None:
    source_rel: str | None = None
    for ref in runner_artifacts:
        if ref.kind == ArtifactKind.STATA_EXPORT_TABLE:
            source_rel = ref.rel_path
            break
    if source_rel is None:
        write_text(path, "metric,value\\nN,0\\nk,0\\n")
        return
    source = safe_job_rel_resolve(job_dir=job_dir, rel_path=source_rel, step_id=step_id)
    path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, path)


def _copy_primary_binding_as_product(
    *,
    job_dir: Path,
    step_id: str,
    bindings: tuple[ResolvedBinding, ...],
    path: Path,
) -> None:
    primary = next((b for b in bindings if b.role == "primary_dataset"), None)
    if primary is None:
        raise PlanCompositionInvalidError(reason="missing_primary_dataset")
    source = safe_job_rel_resolve(
        job_dir=job_dir,
        rel_path=primary.source_rel_path,
        step_id=step_id,
    )
    path.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, path)


def _product_artifact_path(*, dirs: RunDirs, product_id: str, kind: ProductKind) -> Path:
    base = dirs.artifacts_dir / "products"
    suffix = ".csv" if kind in {ProductKind.DATASET, ProductKind.TABLE} else ".json"
    return base / f"{product_id}{suffix}"
