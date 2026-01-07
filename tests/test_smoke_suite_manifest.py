import json
from pathlib import Path

import jsonschema


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_smoke_suite_manifest_when_validated_against_schema_has_no_errors() -> None:
    repo_root = _repo_root()
    manifest_path = repo_root / "assets/stata_do_library/smoke_suite/manifest.1.0.json"
    schema_path = repo_root / "assets/stata_do_library/schemas/smoke_suite/1.0.schema.json"

    schema = _load_json(schema_path)
    manifest = _load_json(manifest_path)

    validator = jsonschema.Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(manifest), key=lambda err: err.json_path)
    messages = [f"{e.json_path or '$'}: {e.message}" for e in errors]
    assert not messages, "smoke suite manifest schema violations:\n" + "\n".join(messages)


def test_smoke_suite_manifest_when_loaded_references_existing_templates_and_fixtures() -> None:
    repo_root = _repo_root()
    library_dir = repo_root / "assets/stata_do_library"
    manifest = _load_json(library_dir / "smoke_suite/manifest.1.0.json")
    index = _load_json(library_dir / "DO_LIBRARY_INDEX.json")

    tasks = index.get("tasks")
    assert isinstance(tasks, dict)

    templates = manifest.get("templates")
    assert isinstance(templates, dict)

    for template_id, entry in templates.items():
        assert isinstance(template_id, str) and template_id in tasks
        assert isinstance(entry, dict)
        _validate_fixtures(template_id=template_id, entry=entry, library_dir=library_dir)
        _validate_params(template_id=template_id, entry=entry, tasks=tasks, library_dir=library_dir)
        _validate_dependencies(
            template_id=template_id,
            entry=entry,
            tasks=tasks,
            library_dir=library_dir,
        )


def _meta_path(*, library_dir: Path, do_file: str) -> Path:
    do_path = library_dir / "do" / do_file
    return library_dir / "do" / "meta" / f"{do_path.stem}.meta.json"


def _validate_fixtures(*, template_id: str, entry: dict, library_dir: Path) -> None:
    fixtures = entry.get("fixtures", [])
    assert isinstance(fixtures, list) and fixtures

    for fixture in fixtures:
        assert isinstance(fixture, dict)
        source = fixture.get("source")
        dest = fixture.get("dest")
        assert isinstance(source, str) and source.strip() != ""
        assert isinstance(dest, str) and dest.strip() != "" and "/" not in dest and "\\" not in dest
        assert (library_dir / source).is_file(), f"{template_id}: missing fixture source: {source}"


def _validate_params(*, template_id: str, entry: dict, tasks: dict, library_dir: Path) -> None:
    params = entry.get("params", {})
    assert isinstance(params, dict)

    do_file = tasks[template_id].get("do_file")
    assert isinstance(do_file, str) and do_file.strip() != ""
    meta_path = _meta_path(library_dir=library_dir, do_file=do_file)
    meta = _load_json(meta_path)

    inputs = meta.get("inputs", [])
    assert isinstance(inputs, list) and inputs
    input_names = {i.get("name") for i in inputs if isinstance(i, dict)}
    fixture_dests = {f.get("dest") for f in entry.get("fixtures", []) if isinstance(f, dict)}
    assert fixture_dests.issubset(input_names), (
        f"{template_id}: fixture dest not declared in meta.inputs"
    )

    required = {
        p.get("name")
        for p in meta.get("parameters", [])
        if isinstance(p, dict) and bool(p.get("required", False))
    }
    required_names = {name for name in required if isinstance(name, str) and name.strip() != ""}
    assert required_names.issubset(set(params.keys())), f"{template_id}: missing required params"

    for key, value in params.items():
        assert isinstance(key, str) and key.strip() != ""
        assert isinstance(value, str)


def _validate_dependencies(
    *, template_id: str, entry: dict, tasks: dict, library_dir: Path
) -> None:
    manifest_deps = entry.get("dependencies", [])
    assert isinstance(manifest_deps, list)

    do_file = tasks[template_id].get("do_file")
    assert isinstance(do_file, str) and do_file.strip() != ""
    meta_path = _meta_path(library_dir=library_dir, do_file=do_file)
    meta = _load_json(meta_path)
    meta_deps = meta.get("dependencies", [])
    assert isinstance(meta_deps, list)

    meta_pairs = {
        (d.get("pkg"), d.get("source"))
        for d in meta_deps
        if isinstance(d, dict)
        and isinstance(d.get("pkg"), str)
        and isinstance(d.get("source"), str)
    }
    for dep in manifest_deps:
        assert isinstance(dep, dict)
        pkg = dep.get("pkg")
        source = dep.get("source")
        assert (pkg, source) in meta_pairs, (
            f"{template_id}: dependency not declared in meta: {pkg}:{source}"
        )
