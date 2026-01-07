import json
from collections import Counter
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def _load_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_do_library_index_when_summarized_matches_tasks_audit_fields() -> None:
    repo_root = _repo_root()
    index_path = repo_root / "assets/stata_do_library/DO_LIBRARY_INDEX.json"
    index = _load_json(index_path)

    tasks = index["tasks"]
    assert isinstance(tasks, dict)

    verdicts = Counter(task["audit"]["verdict"] for task in tasks.values())
    anchor_compliant = sum(1 for task in tasks.values() if task["audit"]["has_ss_anchors"])
    hardcoded_path_free = sum(
        1 for task in tasks.values() if not task["audit"]["has_hardcoded_paths"]
    )
    dangerous_command_free = sum(
        1 for task in tasks.values() if not task["audit"]["has_dangerous_commands"]
    )

    expected_compliance_summary = {
        "prod_ready": verdicts.get("PROD_READY", 0),
        "needs_rework": verdicts.get("NEEDS_REWORK", 0),
        "forbidden": verdicts.get("FORBIDDEN", 0),
        "anchor_compliant": anchor_compliant,
        "hardcoded_path_free": hardcoded_path_free,
        "dangerous_command_free": dangerous_command_free,
    }

    assert index["total_tasks"] == len(tasks)
    assert index["compliance_summary"] == expected_compliance_summary


def test_do_library_index_families_when_counted_match_tasks() -> None:
    repo_root = _repo_root()
    index_path = repo_root / "assets/stata_do_library/DO_LIBRARY_INDEX.json"
    index = _load_json(index_path)

    tasks = index["tasks"]
    assert isinstance(tasks, dict)

    families = index["families"]
    assert isinstance(families, dict)

    task_to_family: dict[str, str] = {}
    for family_name, family_meta in families.items():
        assert isinstance(family_meta, dict)

        task_ids = family_meta["tasks"]
        assert isinstance(task_ids, list)
        assert len(set(task_ids)) == len(task_ids)

        for task_id in task_ids:
            assert task_id in tasks, f"family={family_name} includes unknown task_id={task_id}"
            previous = task_to_family.get(task_id)
            assert previous is None, (
                f"task_id={task_id} appears in multiple families: {previous}, {family_name}"
            )
            task_to_family[task_id] = family_name

    assert set(task_to_family.keys()) == set(tasks.keys())

    for task_id, task in tasks.items():
        assert task_to_family[task_id] == task["family"]
