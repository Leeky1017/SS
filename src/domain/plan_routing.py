from __future__ import annotations

from collections.abc import Mapping

from src.domain.composition_plan import CompositionMode


def extract_input_dataset_keys(*, manifest: Mapping[str, object]) -> set[str]:
    keys: set[str] = set()
    datasets = manifest.get("datasets")
    if isinstance(datasets, list):
        for item in datasets:
            if not isinstance(item, Mapping):
                continue
            dataset_key = item.get("dataset_key")
            if isinstance(dataset_key, str) and dataset_key.strip() != "":
                keys.add(dataset_key.strip())

    primary = manifest.get("primary_dataset")
    if isinstance(primary, Mapping):
        dataset_key = primary.get("dataset_key")
        if isinstance(dataset_key, str) and dataset_key.strip() != "":
            keys.add(dataset_key.strip())

    if len(keys) == 0:
        keys.add("primary")
    return keys


def choose_composition_mode(*, requirement: str, input_keys: set[str]) -> CompositionMode:
    if len(input_keys) <= 1:
        return CompositionMode.SEQUENTIAL

    lowered = requirement.lower()
    if _looks_conditional(lowered):
        return CompositionMode.CONDITIONAL
    if _looks_parallel(lowered):
        return CompositionMode.PARALLEL_THEN_AGGREGATE
    return CompositionMode.MERGE_THEN_SEQUENTIAL


def _looks_conditional(requirement_lowered: str) -> bool:
    return any(token in requirement_lowered for token in (" if ", " else ", " otherwise "))


def _looks_parallel(requirement_lowered: str) -> bool:
    tokens = (
        " separately",
        " each dataset",
        " per dataset",
        " compare across",
        " by dataset",
    )
    return any(token in requirement_lowered for token in tokens)

