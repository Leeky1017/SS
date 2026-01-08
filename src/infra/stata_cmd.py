from __future__ import annotations

import logging
import os
import shutil
import subprocess
from pathlib import Path
from typing import Sequence

from src.config import Config
from src.infra.exceptions import SSError, StataCmdNotFoundError

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
        cmd = list(config.stata_cmd)
        _validate_wsl_windows_interop(stata_cmd=cmd)
        return cmd

    for candidate in ("stata-mp", "stata", "StataMP-64.exe", "StataSE-64.exe"):
        found = shutil.which(candidate)
        if found is not None and found != "":
            logger.info("SS_STATA_CMD_RESOLVED", extra={"source": "which", "cmd": [found]})
            return [found]

    for candidate in _WINDOWS_STATA_CANDIDATES:
        if Path(candidate).exists():
            cmd = [candidate]
            _validate_wsl_windows_interop(stata_cmd=cmd)
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


def _validate_wsl_windows_interop(*, stata_cmd: Sequence[str]) -> None:
    if not _is_windows_stata_cmd(stata_cmd):
        return
    if os.environ.get("WSL_INTEROP", "").strip() == "":
        return
    cmd_exe = Path("/mnt/c/Windows/System32/cmd.exe")
    if not cmd_exe.is_file():
        return

    try:
        completed = subprocess.run(
            [str(cmd_exe), "/c", "exit", "0"],
            text=True,
            capture_output=True,
            check=False,
            timeout=5,
        )
    except subprocess.TimeoutExpired as e:
        raise SSError(
            error_code="WSL_INTEROP_UNAVAILABLE",
            message="wsl windows interop check timed out (cmd.exe)",
            status_code=500,
        ) from e
    except OSError as e:
        raise SSError(
            error_code="WSL_INTEROP_UNAVAILABLE",
            message=f"wsl windows interop check failed (cmd.exe): {e}",
            status_code=500,
        ) from e

    stderr = (completed.stderr or "").strip()
    if completed.returncode != 0:
        msg = f"wsl windows interop unavailable (cmd.exe exit {completed.returncode})"
        if stderr != "":
            msg = msg + f": {stderr}"
        raise SSError(error_code="WSL_INTEROP_UNAVAILABLE", message=msg, status_code=500)


def build_stata_batch_cmd(*, stata_cmd: Sequence[str], do_filename: str) -> list[str]:
    cmd = list(stata_cmd)
    if _is_windows_stata_cmd(stata_cmd):
        return [*cmd, "/e", "do", do_filename]
    return [*cmd, "-b", "do", do_filename]
