from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from src.domain.do_template_repository import DoTemplate, DoTemplateRepository
from src.infra.exceptions import (
    DoTemplateIndexCorruptedError,
    DoTemplateIndexNotFoundError,
    DoTemplateMetaNotFoundError,
    DoTemplateNotFoundError,
    DoTemplateSourceNotFoundError,
)


def _safe_library_filename(value: str) -> bool:
    if value == "":
        return False
    if "/" in value or "\\" in value:
        return False
    if value.startswith("~"):
        return False
    if value in {".", ".."}:
        return False
    return ".." not in Path(value).parts


def _load_json_or_raise(*, path: Path, not_found: Exception, corrupted: Exception) -> dict:
    try:
        raw = path.read_text(encoding="utf-8")
    except FileNotFoundError as e:
        raise not_found from e
    except OSError as e:
        raise corrupted from e
    try:
        data = json.loads(raw)
    except json.JSONDecodeError as e:
        raise corrupted from e
    if not isinstance(data, dict):
        raise corrupted
    return data


def _tasks_mapping(index_payload: dict) -> dict:
    tasks = index_payload.get("tasks", {})
    if not isinstance(tasks, dict):
        raise DoTemplateIndexCorruptedError(reason="index.tasks_invalid")
    return tasks


def _task_record(*, tasks: dict, template_id: str) -> dict:
    record = tasks.get(template_id, None)
    if not isinstance(record, dict):
        raise DoTemplateNotFoundError(template_id=template_id)
    return record


def _do_filename(*, record: dict, template_id: str) -> str:
    value = record.get("do_file", "")
    if not isinstance(value, str) or not _safe_library_filename(value):
        raise DoTemplateIndexCorruptedError(reason="index.do_file_invalid", template_id=template_id)
    return value


def _meta_filename(*, do_filename: str) -> str:
    path = Path(do_filename)
    return f"{path.stem}.meta.json"


@dataclass(frozen=True)
class FileSystemDoTemplateRepository(DoTemplateRepository):
    library_dir: Path
    _cached_index: dict | None = None

    def list_template_ids(self) -> tuple[str, ...]:
        tasks = _tasks_mapping(self._index())
        ids = [str(k) for k in tasks.keys() if isinstance(k, str) and k.strip() != ""]
        return tuple(sorted(set(ids)))

    def get_template(self, *, template_id: str) -> DoTemplate:
        tasks = _tasks_mapping(self._index())
        record = _task_record(tasks=tasks, template_id=template_id)
        do_name = _do_filename(record=record, template_id=template_id)

        do_path = self.library_dir / "do" / do_name
        if not do_path.exists():
            raise DoTemplateSourceNotFoundError(template_id=template_id, path=str(do_path))

        meta_name = _meta_filename(do_filename=do_name)
        if not _safe_library_filename(meta_name):
            raise DoTemplateIndexCorruptedError(
                reason="index.meta_file_invalid",
                template_id=template_id,
            )

        meta_path = self.library_dir / "do" / "meta" / meta_name
        if not meta_path.exists():
            raise DoTemplateMetaNotFoundError(template_id=template_id, path=str(meta_path))

        do_text = do_path.read_text(encoding="utf-8", errors="replace")
        meta = _load_json_or_raise(
            path=meta_path,
            not_found=DoTemplateMetaNotFoundError(template_id=template_id, path=str(meta_path)),
            corrupted=DoTemplateIndexCorruptedError(
                reason="meta.json_invalid",
                template_id=template_id,
            ),
        )
        return DoTemplate(template_id=template_id, do_text=do_text, meta=meta)

    def _index(self) -> dict:
        cached = self._cached_index
        if isinstance(cached, dict):
            return cached
        path = self.library_dir / "DO_LIBRARY_INDEX.json"
        index = _load_json_or_raise(
            path=path,
            not_found=DoTemplateIndexNotFoundError(path=str(path)),
            corrupted=DoTemplateIndexCorruptedError(reason="index.json_invalid"),
        )
        object.__setattr__(self, "_cached_index", index)
        return index
