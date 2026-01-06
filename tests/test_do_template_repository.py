from __future__ import annotations

import json
from pathlib import Path

import pytest

from src.infra.exceptions import (
    DoTemplateIndexCorruptedError,
    DoTemplateMetaNotFoundError,
    DoTemplateNotFoundError,
    DoTemplateSourceNotFoundError,
)
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")


def test_list_template_ids_when_index_present_returns_sorted_ids(tmp_path: Path):
    # Arrange
    _write_json(
        tmp_path / "DO_LIBRARY_INDEX.json",
        {
            "tasks": {
                "B02": {"do_file": "B02.do"},
                "A01": {"do_file": "A01.do"},
            }
        },
    )
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act
    ids = repo.list_template_ids()

    # Assert
    assert ids == ("A01", "B02")


def test_get_template_when_files_exist_returns_do_text_and_meta(tmp_path: Path):
    # Arrange
    _write_json(
        tmp_path / "DO_LIBRARY_INDEX.json",
        {"tasks": {"T01": {"do_file": "T01_desc_overview.do"}}},
    )
    (tmp_path / "do").mkdir(parents=True, exist_ok=True)
    (tmp_path / "do" / "T01_desc_overview.do").write_text('display "__X__"\n', encoding="utf-8")
    _write_json(
        tmp_path / "do" / "meta" / "T01_desc_overview.meta.json",
        {"id": "T01", "parameters": [{"name": "__X__", "required": True}]},
    )
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act
    template = repo.get_template(template_id="T01")

    # Assert
    assert template.template_id == "T01"
    assert template.do_text == 'display "__X__"\n'
    assert template.meta["id"] == "T01"


def test_get_template_when_id_missing_raises_not_found(tmp_path: Path):
    # Arrange
    _write_json(tmp_path / "DO_LIBRARY_INDEX.json", {"tasks": {}})
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act / Assert
    with pytest.raises(DoTemplateNotFoundError):
        repo.get_template(template_id="T404")


def test_get_template_when_do_file_missing_raises_source_not_found(tmp_path: Path):
    # Arrange
    _write_json(
        tmp_path / "DO_LIBRARY_INDEX.json",
        {"tasks": {"T01": {"do_file": "T01_desc_overview.do"}}},
    )
    _write_json(
        tmp_path / "do" / "meta" / "T01_desc_overview.meta.json",
        {"id": "T01"},
    )
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act / Assert
    with pytest.raises(DoTemplateSourceNotFoundError):
        repo.get_template(template_id="T01")


def test_get_template_when_meta_missing_raises_meta_not_found(tmp_path: Path):
    # Arrange
    _write_json(
        tmp_path / "DO_LIBRARY_INDEX.json",
        {"tasks": {"T01": {"do_file": "T01_desc_overview.do"}}},
    )
    (tmp_path / "do").mkdir(parents=True, exist_ok=True)
    (tmp_path / "do" / "T01_desc_overview.do").write_text("display 1\n", encoding="utf-8")
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act / Assert
    with pytest.raises(DoTemplateMetaNotFoundError):
        repo.get_template(template_id="T01")


def test_list_template_ids_when_index_tasks_invalid_raises_corrupted(tmp_path: Path):
    # Arrange
    _write_json(tmp_path / "DO_LIBRARY_INDEX.json", {"tasks": []})
    repo = FileSystemDoTemplateRepository(library_dir=tmp_path)

    # Act / Assert
    with pytest.raises(DoTemplateIndexCorruptedError):
        repo.list_template_ids()

