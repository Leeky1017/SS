from __future__ import annotations

from pathlib import Path

from src.infra.fs_do_template_repository import FileSystemDoTemplateRepository


def cmd_list_templates(*, library_dir: Path, limit: int) -> int:
    repo = FileSystemDoTemplateRepository(library_dir=library_dir)
    template_ids = repo.list_template_ids()
    for template_id in template_ids[: max(0, int(limit))]:
        print(template_id)
    return 0

