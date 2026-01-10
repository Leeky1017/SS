from __future__ import annotations

import json
from pathlib import Path

from src.infra.fs_do_template_catalog import FileSystemDoTemplateCatalog
from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository


def _write_json(path: Path, payload: dict[str, object]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    data = json.dumps(payload, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
    path.write_text(data, encoding="utf-8")


def test_filesystem_do_template_catalog_with_valid_library_lists_families_and_templates(
    tmp_path: Path,
) -> None:
    # Arrange
    library_dir = tmp_path / "lib"
    (library_dir / "do" / "meta").mkdir(parents=True, exist_ok=True)
    (library_dir / "do" / "T01_test.do").write_text("* hello\n", encoding="utf-8")
    _write_json(
        library_dir / "DO_LIBRARY_INDEX.json",
        {
            "families": {
                "data_management": {
                    "description": "Data management",
                    "capabilities": ["describe"],
                    "tasks": ["T01"],
                }
            },
            "tasks": {
                "T01": {
                    "family": "data_management",
                    "name": "Dataset Overview",
                    "slug": "desc_overview",
                    "do_file": "T01_test.do",
                    "placeholders": ["__NUMERIC_VARS__"],
                    "outputs": [{"type": "table", "file": "table.csv"}],
                }
            },
        },
    )

    # Act
    catalog = FileSystemDoTemplateCatalog(library_dir=library_dir)
    families = catalog.list_families()
    templates = catalog.list_templates(family_ids=("data_management",))

    # Assert
    assert len(families) == 1
    assert families[0].family_id == "data_management"
    assert "describe" in families[0].capabilities

    assert len(templates) == 1
    assert templates[0].template_id == "T01"
    assert templates[0].family_id == "data_management"
    assert "__NUMERIC_VARS__" in templates[0].placeholders
    assert "table" in templates[0].output_types


def test_filesystem_do_template_repository_with_valid_library_reads_template_and_meta(
    tmp_path: Path,
) -> None:
    # Arrange
    library_dir = tmp_path / "lib"
    (library_dir / "do" / "meta").mkdir(parents=True, exist_ok=True)
    (library_dir / "do" / "T01_test.do").write_text("* hello\n", encoding="utf-8")
    _write_json(
        library_dir / "do" / "meta" / "T01_test.meta.json",
        {
            "contract_version": "1.1",
            "parameters": [{"name": "__NUMERIC_VARS__", "required": True, "type": "list[string]"}],
            "outputs": [{"type": "table", "file": "table.csv"}],
        },
    )
    _write_json(
        library_dir / "DO_LIBRARY_INDEX.json",
        {
            "families": {"data_management": {"tasks": ["T01"]}},
            "tasks": {"T01": {"do_file": "T01_test.do", "family": "data_management"}},
        },
    )

    # Act
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    ids = repo.list_template_ids()
    template = repo.get_template(template_id="T01")

    # Assert
    assert ids == ("T01",)
    assert template.template_id == "T01"
    assert template.do_text.strip() == "* hello"
    assert template.meta.get("contract_version") == "1.1"
