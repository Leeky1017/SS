from __future__ import annotations

from enum import Enum
from typing import Mapping

from pydantic import BaseModel, ConfigDict, ValidationError, field_validator

from src.domain.models import LLMPlan, PlanStep, is_do_generation_step_type
from src.infra.plan_exceptions import PlanCompositionInvalidError


class CompositionMode(str, Enum):
    SEQUENTIAL = "sequential"
    MERGE_THEN_SEQUENTIAL = "merge_then_sequential"
    PARALLEL_THEN_AGGREGATE = "parallel_then_aggregate"
    CONDITIONAL = "conditional"


class ProductKind(str, Enum):
    DATASET = "dataset"
    TABLE = "table"
    FIGURE = "figure"
    REPORT = "report"


class PlanProduct(BaseModel):
    model_config = ConfigDict(extra="allow")

    product_id: str
    kind: ProductKind
    role: str | None = None

    @field_validator("product_id")
    @classmethod
    def product_id_must_be_non_empty(cls, value: str) -> str:
        if value.strip() == "":
            raise ValueError("product_id must be non-empty")
        return value


class _CompositionParams(BaseModel):
    model_config = ConfigDict(extra="ignore")

    composition_mode: CompositionMode
    template_id: str | None = None
    input_bindings: dict[str, str] | None = None
    products: list[PlanProduct] | None = None


def _parse_dataset_ref(value: str) -> tuple[str, str, str | None]:
    parts = value.split(":")
    if len(parts) == 2 and parts[0] == "input":
        dataset_key = parts[1].strip()
        if dataset_key == "":
            raise ValueError("dataset_key must be non-empty")
        return "input", dataset_key, None
    if len(parts) == 3 and parts[0] == "prod":
        step_id = parts[1].strip()
        product_id = parts[2].strip()
        if step_id == "" or product_id == "":
            raise ValueError("prod refs must include step_id and product_id")
        return "prod", step_id, product_id
    raise ValueError("dataset_ref must match input:<dataset_key> or prod:<step_id>:<product_id>")


def _depends_transitively(
    *,
    consumer_step_id: str,
    producer_step_id: str,
    deps_by_step_id: Mapping[str, list[str]],
) -> bool:
    if consumer_step_id == producer_step_id:
        return True
    seen: set[str] = set()
    stack = list(deps_by_step_id.get(consumer_step_id, []))
    while stack:
        dep = stack.pop()
        if dep == producer_step_id:
            return True
        if dep in seen:
            continue
        seen.add(dep)
        stack.extend(deps_by_step_id.get(dep, []))
    return False


def validate_composition_plan(*, plan: LLMPlan, known_input_keys: set[str]) -> CompositionMode:
    deps_by_step_id = {step.step_id: list(step.depends_on) for step in plan.steps}
    mode, params_by_step_id, products_by_step_id = _collect_step_params(plan=plan)

    for step in plan.steps:
        params = params_by_step_id[step.step_id]
        _validate_step_requirements(step=step, params=params)
        _validate_input_bindings(
            step=step,
            params=params,
            known_input_keys=known_input_keys,
            products_by_step_id=products_by_step_id,
            deps_by_step_id=deps_by_step_id,
        )

    return mode


def _collect_step_params(
    *, plan: LLMPlan
) -> tuple[CompositionMode, dict[str, _CompositionParams], dict[str, set[str]]]:
    mode: CompositionMode | None = None
    params_by_step_id: dict[str, _CompositionParams] = {}
    products_by_step_id: dict[str, set[str]] = {}

    for step in plan.steps:
        params = _parse_step_params(step=step)
        if mode is None:
            mode = params.composition_mode
        elif params.composition_mode != mode:
            raise PlanCompositionInvalidError(
                reason="composition_mode_mismatch",
                step_id=step.step_id,
            )
        params_by_step_id[step.step_id] = params
        products_by_step_id[step.step_id] = _product_ids(step_id=step.step_id, params=params)

    if mode is None:
        raise PlanCompositionInvalidError(reason="missing_steps")
    return mode, params_by_step_id, products_by_step_id


def _parse_step_params(*, step: PlanStep) -> _CompositionParams:
    try:
        return _CompositionParams.model_validate(step.params)
    except ValidationError as e:
        raise PlanCompositionInvalidError(
            reason="composition_params_schema_invalid",
            step_id=step.step_id,
        ) from e


def _product_ids(*, step_id: str, params: _CompositionParams) -> set[str]:
    products = [] if params.products is None else params.products
    seen_product_ids: set[str] = set()
    for product in products:
        if product.product_id in seen_product_ids:
            raise PlanCompositionInvalidError(
                reason="duplicate_product_id",
                step_id=step_id,
                product_id=product.product_id,
            )
        seen_product_ids.add(product.product_id)
    return seen_product_ids


def _validate_step_requirements(*, step: PlanStep, params: _CompositionParams) -> None:
    if not is_do_generation_step_type(step.type):
        return
    template_id = params.template_id
    if template_id is None or template_id.strip() == "":
        raise PlanCompositionInvalidError(reason="missing_template_id", step_id=step.step_id)

    bindings = params.input_bindings
    if bindings is None or len(bindings) == 0:
        raise PlanCompositionInvalidError(reason="missing_input_bindings", step_id=step.step_id)

    if params.products is None:
        raise PlanCompositionInvalidError(reason="missing_products", step_id=step.step_id)


def _validate_input_bindings(
    *,
    step: PlanStep,
    params: _CompositionParams,
    known_input_keys: set[str],
    products_by_step_id: Mapping[str, set[str]],
    deps_by_step_id: Mapping[str, list[str]],
) -> None:
    bindings = {} if params.input_bindings is None else params.input_bindings
    for role, dataset_ref in bindings.items():
        _validate_input_binding(
            step_id=step.step_id,
            role=role,
            dataset_ref=dataset_ref,
            known_input_keys=known_input_keys,
            products_by_step_id=products_by_step_id,
            deps_by_step_id=deps_by_step_id,
        )


def _parse_dataset_ref_or_error(*, step_id: str, dataset_ref: str) -> tuple[str, str, str | None]:
    try:
        return _parse_dataset_ref(dataset_ref)
    except ValueError as e:
        raise PlanCompositionInvalidError(
            reason="dataset_ref_invalid",
            step_id=step_id,
            dataset_ref=dataset_ref,
        ) from e


def _validate_input_binding(
    *,
    step_id: str,
    role: str,
    dataset_ref: str,
    known_input_keys: set[str],
    products_by_step_id: Mapping[str, set[str]],
    deps_by_step_id: Mapping[str, list[str]],
) -> None:
    if role.strip() == "":
        raise PlanCompositionInvalidError(reason="input_binding_role_empty", step_id=step_id)
    if dataset_ref.strip() == "":
        raise PlanCompositionInvalidError(reason="dataset_ref_empty", step_id=step_id)
    kind, a, b = _parse_dataset_ref_or_error(step_id=step_id, dataset_ref=dataset_ref)
    if kind == "input":
        if a not in known_input_keys:
            raise PlanCompositionInvalidError(
                reason="unknown_input_dataset",
                step_id=step_id,
                dataset_ref=dataset_ref,
            )
        return

    producer_step_id = a
    product_id = "" if b is None else b
    known_products = products_by_step_id.get(producer_step_id)
    if known_products is None:
        raise PlanCompositionInvalidError(
            reason="unknown_product_step",
            step_id=step_id,
            dataset_ref=dataset_ref,
        )
    if product_id not in known_products:
        raise PlanCompositionInvalidError(
            reason="unknown_product_id",
            step_id=step_id,
            dataset_ref=dataset_ref,
        )
    if _depends_transitively(
        consumer_step_id=step_id,
        producer_step_id=producer_step_id,
        deps_by_step_id=deps_by_step_id,
    ):
        return
    raise PlanCompositionInvalidError(
        reason="missing_dependency_for_product",
        step_id=step_id,
        dataset_ref=dataset_ref,
    )
