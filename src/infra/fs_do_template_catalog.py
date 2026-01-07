from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import cast

from src.domain.do_template_catalog import DoTemplateCatalog, FamilySummary, TemplateSummary
from src.infra.exceptions import DoTemplateIndexCorruptedError, DoTemplateIndexNotFoundError
from src.utils.json_types import JsonObject


def _load_json_or_raise(*, path: Path) -> JsonObject:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise DoTemplateIndexNotFoundError(path=str(path)) from e
    except OSError as e:
        raise DoTemplateIndexCorruptedError(reason="index.read_failed") from e
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise DoTemplateIndexCorruptedError(reason="index.json_invalid") from e
    if not isinstance(data, dict):
        raise DoTemplateIndexCorruptedError(reason="index.not_object")
    return cast(JsonObject, data)


def _index_families(index: JsonObject) -> dict[str, JsonObject]:
    raw = index.get("families", {})
    if not isinstance(raw, dict):
        raise DoTemplateIndexCorruptedError(reason="index.families_invalid")
    return cast(dict[str, JsonObject], raw)


def _index_tasks(index: JsonObject) -> dict[str, JsonObject]:
    raw = index.get("tasks", {})
    if not isinstance(raw, dict):
        raise DoTemplateIndexCorruptedError(reason="index.tasks_invalid")
    return cast(dict[str, JsonObject], raw)


def _output_types_from_task_record(record: JsonObject) -> tuple[str, ...]:
    raw = record.get("outputs", [])
    if raw is None:
        return tuple()
    if not isinstance(raw, list):
        return tuple()
    types: list[str] = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        value = item.get("type", "")
        if isinstance(value, str) and value.strip() != "":
            types.append(value.strip())
    return tuple(sorted(set(types)))


def _placeholders_from_task_record(record: JsonObject) -> tuple[str, ...]:
    raw = record.get("placeholders", [])
    if raw is None:
        return tuple()
    if not isinstance(raw, list):
        return tuple()
    names: list[str] = []
    for item in raw:
        if isinstance(item, str) and item.strip() != "":
            names.append(item.strip())
    return tuple(sorted(set(names)))


@dataclass(frozen=True)
class FileSystemDoTemplateCatalog(DoTemplateCatalog):
    library_dir: Path
    _cached_index: JsonObject | None = None

    def list_families(self) -> tuple[FamilySummary, ...]:
        families = _index_families(self._index())
        items: list[FamilySummary] = []
        for family_id, record in families.items():
            if not isinstance(family_id, str) or family_id.strip() == "":
                continue
            if not isinstance(record, dict):
                raise DoTemplateIndexCorruptedError(reason="index.family_record_invalid")
            description = record.get("description", "")
            if not isinstance(description, str):
                description = ""
            capabilities = record.get("capabilities", [])
            if not isinstance(capabilities, list):
                capabilities = []
            capabilities_clean = [
                c.strip() for c in capabilities if isinstance(c, str) and c.strip() != ""
            ]
            task_ids = record.get("tasks", [])
            if not isinstance(task_ids, list):
                task_ids = []
            task_ids_clean = [t.strip() for t in task_ids if isinstance(t, str) and t.strip() != ""]
            items.append(
                FamilySummary(
                    family_id=family_id.strip(),
                    description=description.strip(),
                    capabilities=tuple(sorted(set(capabilities_clean))),
                    template_ids=tuple(sorted(set(task_ids_clean))),
                )
            )
        return tuple(sorted(items, key=lambda x: x.family_id))

    def list_templates(self, *, family_ids: tuple[str, ...]) -> tuple[TemplateSummary, ...]:
        family_set = {f.strip() for f in family_ids if isinstance(f, str) and f.strip() != ""}
        if not family_set:
            return tuple()
        tasks = _index_tasks(self._index())
        items: list[TemplateSummary] = []
        for template_id, record in tasks.items():
            if not isinstance(record, dict):
                continue
            family_id = record.get("family", "")
            if not isinstance(family_id, str) or family_id.strip() == "":
                continue
            if family_id.strip() not in family_set:
                continue
            name = record.get("name", "")
            slug = record.get("slug", "")
            items.append(
                TemplateSummary(
                    template_id=str(template_id).strip(),
                    family_id=family_id.strip(),
                    name=name if isinstance(name, str) else "",
                    slug=slug if isinstance(slug, str) else "",
                    placeholders=_placeholders_from_task_record(record),
                    output_types=_output_types_from_task_record(record),
                )
            )
        return tuple(sorted(items, key=lambda x: x.template_id))

    def _index(self) -> JsonObject:
        cached = self._cached_index
        if cached is not None:
            return cached
        path = Path(self.library_dir) / "DO_LIBRARY_INDEX.json"
        index = _load_json_or_raise(path=path)
        object.__setattr__(self, "_cached_index", index)
        return index

