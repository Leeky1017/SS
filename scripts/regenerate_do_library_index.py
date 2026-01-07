#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import sys
from collections import Counter
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_index_json(path: Path, payload: dict[str, Any]) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def _write_compact_json(path: Path, payload: Any) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )


def _find_single_do_file(*, do_dir: Path, template_id: str) -> str:
    matches = sorted(p.name for p in do_dir.glob(f"{template_id}_*.do") if p.is_file())
    if len(matches) != 1:
        raise ValueError(f"do_library_index.do_file_ambiguous:{template_id}:{len(matches)}")
    return matches[0]


def _canonical_outputs(meta: dict[str, Any]) -> list[str]:
    outputs = meta.get("outputs", [])
    if not isinstance(outputs, list):
        return []
    items: list[str] = []
    for item in outputs:
        if not isinstance(item, dict):
            continue
        file = item.get("file", "")
        if isinstance(file, str) and file.strip() != "":
            items.append(file.strip())
    return list(dict.fromkeys(items))


def _canonical_placeholders(meta: dict[str, Any]) -> list[str]:
    params = meta.get("parameters", [])
    if not isinstance(params, list):
        return []
    items: list[str] = []
    for item in params:
        if not isinstance(item, dict):
            continue
        name = item.get("name", "")
        if isinstance(name, str) and name.strip() != "":
            items.append(name.strip())
    return list(dict.fromkeys(items))


def _default_audit() -> dict[str, Any]:
    return {
        "verdict": "PROD_READY",
        "has_ss_anchors": True,
        "has_hardcoded_paths": False,
        "has_dangerous_commands": False,
        "uses_seed": False,
        "rework_items": [],
    }


def _audit_for(*, template_id: str, previous_tasks: dict[str, Any]) -> dict[str, Any]:
    previous = previous_tasks.get(template_id, {})
    if not isinstance(previous, dict):
        return _default_audit()
    audit = previous.get("audit", {})
    if not isinstance(audit, dict):
        return _default_audit()
    merged = _default_audit() | audit
    merged["rework_items"] = (
        merged["rework_items"]
        if isinstance(merged.get("rework_items"), list)
        else _default_audit()["rework_items"]
    )
    return merged


def regenerate(*, library_dir: Path) -> None:
    do_dir = library_dir / "do"
    meta_dir = do_dir / "meta"
    docs_dir = library_dir / "docs"
    index_path = library_dir / "DO_LIBRARY_INDEX.json"

    previous_index = _load_json(index_path) if index_path.exists() else {}
    previous_tasks = previous_index.get("tasks", {})
    previous_families = previous_index.get("families", {})
    if not isinstance(previous_tasks, dict):
        previous_tasks = {}
    if not isinstance(previous_families, dict):
        previous_families = {}

    meta_files = sorted(meta_dir.glob("*.meta.json"))
    tasks: dict[str, Any] = {}
    families: dict[str, Any] = {}

    for meta_path in meta_files:
        meta = _load_json(meta_path)
        template_id = meta.get("id", "")
        if not isinstance(template_id, str) or template_id.strip() == "":
            raise ValueError(f"do_library_index.meta_missing_id:{meta_path}")
        template_id = template_id.strip()
        family_id = meta.get("family", "")
        if not isinstance(family_id, str) or family_id.strip() == "":
            raise ValueError(f"do_library_index.meta_missing_family:{template_id}")
        family_id = family_id.strip()

        do_file = _find_single_do_file(do_dir=do_dir, template_id=template_id)
        md_file = do_file.replace(".do", ".md")
        if not (docs_dir / md_file).exists():
            raise ValueError(f"do_library_index.md_missing:{template_id}:{md_file}")

        title_zh = meta.get("title_zh", "")
        name = (
            title_zh
            if isinstance(title_zh, str) and title_zh.strip() != ""
            else meta.get("title", "")
        )
        tasks[template_id] = {
            "id": template_id,
            "slug": meta.get("slug", "") if isinstance(meta.get("slug", ""), str) else "",
            "name": name if isinstance(name, str) else "",
            "family": family_id,
            "do_file": do_file,
            "md_file": md_file,
            "placeholders": _canonical_placeholders(meta),
            "outputs": _canonical_outputs(meta),
            "audit": _audit_for(template_id=template_id, previous_tasks=previous_tasks),
        }

        family = families.get(family_id)
        if not isinstance(family, dict):
            previous_family = previous_families.get(family_id, {})
            families[family_id] = {
                "description": previous_family.get("description", "")
                if isinstance(previous_family, dict)
                else "",
                "tasks": [],
                "capabilities": previous_family.get("capabilities", [])
                if isinstance(previous_family, dict)
                else [],
            }
        families[family_id]["tasks"].append(template_id)

    for family_id, record in families.items():
        tasks_list = record.get("tasks", [])
        record["tasks"] = sorted({t for t in tasks_list if isinstance(t, str) and t.strip() != ""})

    verdicts = Counter(task["audit"]["verdict"] for task in tasks.values())
    compliance_summary = {
        "prod_ready": verdicts.get("PROD_READY", 0),
        "needs_rework": verdicts.get("NEEDS_REWORK", 0),
        "forbidden": verdicts.get("FORBIDDEN", 0),
        "anchor_compliant": sum(
            1 for task in tasks.values() if task["audit"].get("has_ss_anchors")
        ),
        "hardcoded_path_free": sum(
            1 for task in tasks.values() if not task["audit"].get("has_hardcoded_paths")
        ),
        "dangerous_command_free": sum(
            1 for task in tasks.values() if not task["audit"].get("has_dangerous_commands")
        ),
    }

    index_payload = {
        "version": str(previous_index.get("version", "2.0.0")),
        "audit_date": dt.date.today().isoformat(),
        "total_tasks": len(tasks),
        "compliance_summary": compliance_summary,
        "families": families,
        "tasks": tasks,
    }
    _write_index_json(index_path, index_payload)

    from src.domain.do_template_taxonomy import generate_family_summary, load_family_registry

    registry_path = library_dir / "taxonomy/family_registry/1.0.json"
    summary_path = library_dir / "taxonomy/family_summary/1.0.json"
    registry = load_family_registry(_load_json(registry_path))
    summary = generate_family_summary(index_payload=index_payload, registry=registry)
    _write_compact_json(summary_path, summary)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--library-dir",
        default="assets/stata_do_library",
        help="Path to the do-template library root (default: assets/stata_do_library)",
    )
    args = parser.parse_args()

    regenerate(library_dir=Path(args.library_dir))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
