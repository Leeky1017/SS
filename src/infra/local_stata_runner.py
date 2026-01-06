from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Callable, Sequence

from src.domain.stata_runner import RunResult, StataRunner
from src.infra.stata_run_attempt import run_local_stata_attempt


class LocalStataRunner(StataRunner):
    def __init__(
        self,
        *,
        jobs_dir: Path,
        stata_cmd: Sequence[str],
        subprocess_runner: Callable[..., subprocess.CompletedProcess[str]] | None = None,
    ):
        self._jobs_dir = Path(jobs_dir)
        self._stata_cmd = list(stata_cmd)
        self._subprocess_runner = subprocess_runner

    def run(
        self,
        *,
        job_id: str,
        run_id: str,
        do_file: str,
        timeout_seconds: int | None = None,
    ) -> RunResult:
        return run_local_stata_attempt(
            jobs_dir=self._jobs_dir,
            job_id=job_id,
            run_id=run_id,
            do_file=do_file,
            stata_cmd=self._stata_cmd,
            timeout_seconds=timeout_seconds,
            subprocess_runner=self._subprocess_runner,
        )
