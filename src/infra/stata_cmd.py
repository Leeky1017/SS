from __future__ import annotations

import logging
import shutil
from pathlib import Path
from typing import Sequence

from src.config import Config
from src.infra.exceptions import StataCmdNotFoundError

logger = logging.getLogger(__name__)

_WINDOWS_STATA_CANDIDATES = (
    "/mnt/c/Program Files/Stata18/StataMP-64.exe",
    "/mnt/c/Program Files/Stata18/StataSE-64.exe",
    "/mnt/c/Program Files/Stata18/StataBE-64.exe",
    "/mnt/c/Program Files/Stata18/StataMP.exe",
    "/mnt/c/Program Files/Stata18/StataSE.exe",
    "/mnt/c/Program Files/Stata18/StataBE.exe",
)


def resolve_stata_cmd(config: Config) -> list[str]:
    if config.stata_cmd:
        return list(config.stata_cmd)

    for candidate in ("stata-mp", "stata", "StataMP-64.exe", "StataSE-64.exe"):
        found = shutil.which(candidate)
        if found is not None and found != "":
            logger.info("SS_STATA_CMD_RESOLVED", extra={"source": "which", "cmd": [found]})
            return [found]

    for candidate in _WINDOWS_STATA_CANDIDATES:
        if Path(candidate).exists():
            cmd = [candidate]
            logger.info("SS_STATA_CMD_RESOLVED", extra={"source": "wsl_default", "cmd": cmd})
            return cmd

    raise StataCmdNotFoundError()


def _is_windows_stata_cmd(stata_cmd: Sequence[str]) -> bool:
    for part in stata_cmd:
        if not isinstance(part, str) or part == "":
            continue
        if not part.lower().endswith(".exe"):
            continue
        if "stata" in Path(part).name.lower():
            return True
    return False


def build_stata_batch_cmd(*, stata_cmd: Sequence[str], do_filename: str) -> list[str]:
    cmd = list(stata_cmd)
    if _is_windows_stata_cmd(stata_cmd):
        return [*cmd, "/e", "do", do_filename]
    return [*cmd, "-b", "do", do_filename]
