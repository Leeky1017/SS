# ISSUE-36

- Issue: #36 https://github.com/Leeky1017/SS/issues/36
- Branch: task/36-do-template-library
- PR: <fill>

## Plan
- Vendor legacy `stata_service/tasks` as a read-only do-template library asset.
- Add `DoTemplateRepository` port + filesystem implementation.
- Run a minimal template → fill params → generate do-file → execute (Stata) → archive artifacts loop.

## Runs
### 2026-01-06 00:00 setup
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "36" "do-template-library"`
- Key output:
  - `Worktree created: .worktrees/issue-36-do-template-library`
  - `Branch: task/36-do-template-library`

### 2026-01-06 22:00 vendor legacy do-template library
- Command:
  - `mkdir -p assets/stata_do_library && cp -a /home/leeky/work/stata_service/tasks/. assets/stata_do_library/`
- Evidence:
  - `assets/stata_do_library/DO_LIBRARY_INDEX.json`

### 2026-01-06 22:01 python venv (dev deps)
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/pip install -e '.[dev]'`

### 2026-01-06 22:02 real Stata run (first attempt)
- Command:
  - `SS_JOBS_DIR=/mnt/c/ss_jobs_issue36 .venv/bin/python -m src.cli run-template --template-id T01 --param '__NUMERIC_VARS__=y x1' --param '__ID_VAR__=id' --param '__TIME_VAR__=time' --sample-data --timeout-seconds 120`
- Key output:
  - `ok=False` (timeout)
- Diagnosis:
  - Windows Stata executable needs `/e do <file>` instead of `-b do <file>` (do-file finished, but process did not exit).

### 2026-01-06 22:05 real Stata run (success)
- Command:
  - `SS_JOBS_DIR=/mnt/c/ss_jobs_issue36 .venv/bin/python -m src.cli run-template --template-id T01 --param '__NUMERIC_VARS__=y x1' --param '__ID_VAR__=id' --param '__TIME_VAR__=time' --sample-data --timeout-seconds 120`
- Key output:
  - `job_id=job_a21a219c10e9b521`
  - `run_id=e822265a58494b5bb45930acf6766d21`
  - `ok=True`
  - `exit_code=0`
- Evidence:
  - `/mnt/c/ss_jobs_issue36/job_a21a219c10e9b521/runs/e822265a58494b5bb45930acf6766d21/artifacts/do_template_run.meta.json`
  - `/mnt/c/ss_jobs_issue36/job_a21a219c10e9b521/runs/e822265a58494b5bb45930acf6766d21/artifacts/outputs/result.log`

### 2026-01-06 22:10 local checks
- Command:
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `42 passed`
