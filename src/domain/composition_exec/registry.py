from __future__ import annotations

from collections.abc import Mapping

from src.domain.composition_exec.conditional import apply_conditional_skip
from src.domain.composition_exec.types import ExecutionState
from src.domain.composition_plan import ProductKind
from src.domain.models import ArtifactKind, ArtifactRef, PlanStep
from src.utils.json_types import JsonObject


def register_products(*, state: ExecutionState, products: tuple[object, ...]) -> None:
    for product in products:
        state.products[(product.step_id, product.product_id)] = product
        state.artifacts.append(
            ArtifactRef(
                kind=_product_artifact_kind(product_kind=product.kind),
                rel_path=product.artifact_rel_path,
            )
        )


def register_decisions(
    *,
    state: ExecutionState,
    step: PlanStep,
    decisions: tuple[JsonObject, ...],
    steps_by_id: Mapping[str, PlanStep],
) -> None:
    for decision in decisions:
        state.decisions.append(decision)
        if decision.get("type") == "conditional":
            state.skip_reason.update(
                apply_conditional_skip(step=step, decision=decision, steps_by_id=steps_by_id)
            )


def _product_artifact_kind(*, product_kind: ProductKind) -> ArtifactKind:
    if product_kind == ProductKind.DATASET:
        return ArtifactKind.COMPOSITION_PRODUCT_DATASET
    return ArtifactKind.COMPOSITION_PRODUCT_TABLE

