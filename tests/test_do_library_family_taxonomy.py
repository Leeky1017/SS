import json
from pathlib import Path

import jsonschema

from src.domain.do_template_taxonomy import (
    canonical_family_by_template_id,
    generate_family_summary,
    load_family_registry,
)


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_family_registry_when_validated_against_schema_has_no_errors() -> None:
    repo_root = _repo_root()
    registry_path = repo_root / "assets/stata_do_library/taxonomy/family_registry/1.0.json"
    schema_path = repo_root / "assets/stata_do_library/schemas/family_registry/1.0.schema.json"

    registry = _load_json(registry_path)
    schema = _load_json(schema_path)

    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(registry), key=lambda err: err.json_path)
    assert not errors, "family registry schema violations:\n" + "\n".join(
        f"{error.json_path or '$'}: {error.message}" for error in errors
    )


def test_family_registry_when_resolving_aliases_returns_canonical_ids() -> None:
    repo_root = _repo_root()
    registry_path = repo_root / "assets/stata_do_library/taxonomy/family_registry/1.0.json"
    registry = load_family_registry(_load_json(registry_path))

    cases = {
        "panel": "panel_data",
        "panel_data": "panel_data",
        "Panel Data": "panel_data",
        "descriptive": "descriptive_statistics",
        "survival": "survival_analysis",
        "audit": "accounting",
    }
    for label, expected in cases.items():
        resolution = registry.resolve(label)
        assert resolution is not None
        assert resolution.canonical_family_id == expected

    assert registry.resolve("unknown_family") is None


def test_do_library_index_tasks_when_canonicalized_have_one_family_each() -> None:
    repo_root = _repo_root()
    registry_path = repo_root / "assets/stata_do_library/taxonomy/family_registry/1.0.json"
    index_path = repo_root / "assets/stata_do_library/DO_LIBRARY_INDEX.json"

    registry = load_family_registry(_load_json(registry_path))
    index = _load_json(index_path)

    mapping = canonical_family_by_template_id(index_payload=index, registry=registry)

    tasks = index["tasks"]
    assert isinstance(tasks, dict)
    assert set(mapping.keys()) == set(tasks.keys())

    canonical_ids = {family.family_id for family in registry.families}
    assert set(mapping.values()).issubset(canonical_ids)


def test_family_summary_when_regenerated_matches_committed_file() -> None:
    repo_root = _repo_root()
    registry_path = repo_root / "assets/stata_do_library/taxonomy/family_registry/1.0.json"
    index_path = repo_root / "assets/stata_do_library/DO_LIBRARY_INDEX.json"
    summary_path = repo_root / "assets/stata_do_library/taxonomy/family_summary/1.0.json"

    registry = load_family_registry(_load_json(registry_path))
    index = _load_json(index_path)
    summary = generate_family_summary(index_payload=index, registry=registry)

    expected = summary_path.read_text(encoding="utf-8")
    actual = json.dumps(summary, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
    assert expected == actual


def test_family_summary_when_token_budgeted_is_small_enough() -> None:
    repo_root = _repo_root()
    summary_path = repo_root / "assets/stata_do_library/taxonomy/family_summary/1.0.json"

    assert summary_path.stat().st_size <= 12_000

