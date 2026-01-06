from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class DoTemplate:
    template_id: str
    do_text: str
    meta: dict


class DoTemplateRepository(Protocol):
    def list_template_ids(self) -> tuple[str, ...]: ...

    def get_template(self, *, template_id: str) -> DoTemplate: ...

