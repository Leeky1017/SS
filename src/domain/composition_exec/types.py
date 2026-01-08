from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from src.domain.composition_plan import ProductKind
from src.domain.models import ArtifactRef, PlanStep
from src.utils.json_types import JsonObject


@dataclass(frozen=True)
class ResolvedBinding:
    role: str
    dataset_ref: str
    source_rel_path: str
    dest_filename: str
    dataset_key: str


@dataclass(frozen=True)
class ResolvedProduct:
    step_id: str
    product_id: str
    kind: ProductKind
    artifact_rel_path: str


@dataclass(frozen=True)
class MaterializedStepInputs:
    inputs_dir: Path
    bindings: tuple[ResolvedBinding, ...]
    manifest: JsonObject


@dataclass
class ExecutionState:
    products: dict[tuple[str, str], ResolvedProduct]
    step_summaries: list[JsonObject]
    skip_reason: dict[str, str]
    decisions: list[JsonObject]
    artifacts: list[ArtifactRef]


@dataclass(frozen=True)
class StepContext:
    step: PlanStep
    run_id: str

