from __future__ import annotations

import re
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Sequence

from src.domain.stata_runner import RunError
from src.infra.stata_run_filenames import STATA_LOG_FILENAME

_STATA_RETURN_CODE_RE = re.compile(r"^\s*r\((?P<code>\d+)\);", re.MULTILINE)


@dataclass(frozen=True)
class Execution:
    stdout_text: str
    stderr_text: str
    exit_code: int | None
    timed_out: bool
    duration_ms: int
    error: RunError | None


def coerce_text(value: str | bytes | None) -> str:
    if value is None:
        return ""
    if isinstance(value, bytes):
        return value.decode("utf-8", errors="replace")
    return value


def _extract_stata_return_code_error(*, log_text: str) -> RunError | None:
    last_match = None
    for match in _STATA_RETURN_CODE_RE.finditer(log_text):
        last_match = match
    if last_match is None:
        return None
    code = int(last_match.group("code"))
    if code == 0:
        return None
    return RunError("STATA_RETURN_CODE", f"stata log contains r({code});")


def read_stata_log_text(*, cwd: Path) -> str:
    path = cwd / STATA_LOG_FILENAME
    if not path.is_file():
        return ""
    try:
        return path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return ""


def execute(
    *,
    cmd: Sequence[str],
    cwd: Path,
    timeout_seconds: int | None,
    runner: Callable[..., subprocess.CompletedProcess[str]] | None,
) -> Execution:
    started = time.time()
    try:
        run = subprocess.run if runner is None else runner
        completed = run(
            cmd,
            cwd=str(cwd),
            timeout=timeout_seconds,
            text=True,
            capture_output=True,
            check=False,
        )
        exit_code = int(completed.returncode)
        timed_out = False
        if exit_code == 0:
            error = _extract_stata_return_code_error(log_text=read_stata_log_text(cwd=cwd))
        else:
            error = RunError("STATA_NONZERO_EXIT", f"stata exited with code {exit_code}")
        stdout_text = coerce_text(completed.stdout)
        stderr_text = coerce_text(completed.stderr)
    except subprocess.TimeoutExpired as e:
        stdout_text = coerce_text(e.stdout)
        stderr_text = coerce_text(e.stderr)
        exit_code = None
        timed_out = True
        error = RunError("STATA_TIMEOUT", "stata execution timed out")
    except OSError as e:
        stdout_text = ""
        stderr_text = str(e)
        exit_code = None
        timed_out = False
        error = RunError("STATA_SUBPROCESS_FAILED", str(e))
    duration_ms = int((time.time() - started) * 1000)
    return Execution(
        stdout_text=stdout_text,
        stderr_text=stderr_text,
        exit_code=exit_code,
        timed_out=timed_out,
        duration_ms=duration_ms,
        error=error,
    )

