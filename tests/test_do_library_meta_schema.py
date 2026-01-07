import json
from pathlib import Path

import jsonschema


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_do_meta_json_files_when_validated_against_schema_have_no_errors() -> None:
    repo_root = _repo_root()
    meta_dir = repo_root / "assets/stata_do_library/do/meta"
    schema_dir = repo_root / "assets/stata_do_library/schemas/do_meta"

    meta_files = sorted(meta_dir.glob("*.meta.json"))
    assert meta_files, f"no meta files found under {meta_dir}"

    validator_by_contract_version: dict[str, jsonschema.Draft202012Validator] = {}
    violations: list[str] = []

    for meta_path in meta_files:
        meta = _load_json(meta_path)
        contract_version = meta.get("contract_version")
        if contract_version is None:
            violations.append(f"{meta_path}: missing contract_version")
            continue

        validator = validator_by_contract_version.get(contract_version)
        if validator is None:
            schema_path = schema_dir / f"{contract_version}.schema.json"
            if not schema_path.exists():
                violations.append(
                    f"{meta_path}: unknown contract_version={contract_version} "
                    f"(missing schema: {schema_path})"
                )
                continue
            schema = _load_json(schema_path)
            validator = jsonschema.Draft202012Validator(schema)
            validator_by_contract_version[contract_version] = validator

        for error in sorted(validator.iter_errors(meta), key=lambda err: err.json_path):
            json_path = error.json_path or "$"
            violations.append(f"{meta_path}: {json_path}: {error.message}")

    assert not violations, "do/meta schema violations:\n" + "\n".join(violations)
