from __future__ import annotations

import logging
import os
import re
import shutil
from pathlib import Path

logger = logging.getLogger(__name__)

_ABS_POSIX_QUOTED = re.compile(r"[\"']\\s*/")
_ABS_WINDOWS = re.compile(r"(?:^|[\\s\\\"'])[A-Za-z]:[\\\\/]")


def find_unsafe_dofile_reason(do_file: str) -> str | None:
    for idx, raw_line in enumerate(do_file.splitlines(), start=1):
        line = raw_line.lstrip()
        if line == "" or line.startswith("*"):
            continue
        lowered = line.lower()
        tokens = lowered.replace(",", " ").split()
        if line.startswith("!"):
            return f"shell_bang (line {idx})"
        if lowered.startswith("shell") and (len(lowered) == 5 or not lowered[5].isalnum()):
            return f"shell_command (line {idx})"
        if ".." in tokens or "../" in line or "..\\" in line:
            return f"path_traversal (line {idx})"
        for token in tokens:
            stripped = token.strip("\"'")
            if stripped.startswith("/") and len(stripped) > 1:
                return f"absolute_path (line {idx})"
        if _ABS_POSIX_QUOTED.search(line) or _ABS_WINDOWS.search(line):
            return f"absolute_path (line {idx})"
    return None


def copy_job_inputs_dir(*, job_dir: Path, work_dir: Path) -> None:
    source_dir = job_dir / "inputs"
    if not source_dir.exists() or not source_dir.is_dir():
        return
    target_dir = work_dir / "inputs"
    for root, dirs, files in os.walk(source_dir, followlinks=False):
        root_path = Path(root)
        dirs[:] = [name for name in dirs if not (root_path / name).is_symlink()]
        for name in files:
            source = root_path / name
            if source.is_symlink():
                logger.warning(
                    "SS_STATA_RUN_INPUT_SYMLINK_SKIPPED",
                    extra={"path": str(source)},
                )
                continue
            rel = source.relative_to(source_dir)
            dest = target_dir / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, dest)
