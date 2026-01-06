from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class LocalStorage:
    """Minimal local storage placeholder (YAGNI: only path resolution)."""

    root: Path

    def resolve(self, rel: str) -> Path:
        return (self.root / rel).resolve()
