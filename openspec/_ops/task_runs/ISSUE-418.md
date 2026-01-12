# ISSUE-418
- Issue: #418
- Branch: task/418-worker-coverage
- PR: <fill-after-created>

## Goal
- Add unit tests for worker internals (claim handling / retry / pre-run errors) and raise worker-path coverage.

## Status
- CURRENT: Spec-first setup complete; implementing tests.

## Next Actions
- [ ] Fill Rulebook proposal/tasks + add spec delta.
- [ ] Add focused unit tests for worker internals (no network, no flaky timing).
- [ ] Run `ruff check .`, `mypy`, `pytest -q --cov=src`, then open PR + auto-merge and verify merge.

## Decisions Made
- 2026-01-12 Prefer unit tests over end-to-end worker loops to keep coverage stable and fast.

## Errors Encountered
- None.

## Runs
### 2026-01-12 Create Issue
- Command:
  - `gh issue create -t "[COVERAGE] Worker: raise core execution coverage to 80%+" -b "<body>"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/418`
- Evidence:
  - N/A

### 2026-01-12 Create worktree
- Command:
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "418" "worker-coverage"`
- Key output:
  - `Worktree created: .worktrees/issue-418-worker-coverage`
  - `Branch: task/418-worker-coverage`
- Evidence:
  - N/A

### 2026-01-12 Create Rulebook task (spec-first)
- Command:
  - `rulebook task create issue-418-worker-coverage`
  - `rulebook task validate issue-418-worker-coverage`
- Key output:
  - `Task issue-418-worker-coverage created successfully`
  - `Task issue-418-worker-coverage is valid`
- Evidence:
  - `rulebook/tasks/issue-418-worker-coverage/`

### 2026-01-12 Local tooling setup
- Command:
  - `python3 -m venv .venv`
  - `.venv/bin/python -m pip install --upgrade pip`
  - `.venv/bin/pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ...`
- Evidence:
  - `.venv/`

### 2026-01-12 Lint + type check
- Command:
  - `.venv/bin/ruff check .`
  - `.venv/bin/mypy`
- Key output:
  - `All checks passed!`
  - `Success: no issues found in 175 source files`
- Evidence:
  - N/A

### 2026-01-12 Tests + coverage
- Command:
  - `.venv/bin/pytest -q --cov=src --cov-report=term-missing --cov-fail-under=75`
- Key output:
  - `215 passed, 5 skipped`
  - `Required test coverage of 75% reached. Total coverage: 78.19%`
- Evidence:
  - N/A

### 2026-01-12 Verify worker module coverage
- Command:
  - `.venv/bin/python -m coverage report -m | rg 'src/(domain/worker_(claim_handling|retry|pre_run_error|service)\\.py|worker\\.py)'`
- Key output:
  - `src/domain/worker_claim_handling.py ... 100%`
  - `src/domain/worker_pre_run_error.py ... 100%`
  - `src/domain/worker_retry.py ... 88%`
  - `src/domain/worker_service.py ... 89%`
- Evidence:
  - N/A
