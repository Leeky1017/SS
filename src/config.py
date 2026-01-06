from __future__ import annotations

import os
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping


@dataclass(frozen=True)
class Config:
    jobs_dir: Path
    log_level: str


def load_config(env: Mapping[str, str] | None = None) -> Config:
    """Load config from environment variables with explicit defaults."""
    e = os.environ if env is None else env
    jobs_dir = Path(str(e.get("SS_JOBS_DIR", "./jobs"))).expanduser()
    log_level = str(e.get("SS_LOG_LEVEL", "INFO")).strip().upper()
    return Config(jobs_dir=jobs_dir, log_level=log_level)
