# Tasks: ISSUE-75

- [x] Add mypy dev dependency + strict config in `pyproject.toml`
- [x] Add a CI type-check step (mypy) and fail on typing errors
- [x] Fill missing return type annotations (or refactor to be typable)
- [x] Add a short developer workflow note (how to run mypy locally)
- [x] Run `mypy`, `ruff check .`, and `pytest -q` and record output in `openspec/_ops/task_runs/ISSUE-75.md`
- [x] Run `scripts/agent_pr_preflight.sh` and record output in `openspec/_ops/task_runs/ISSUE-75.md`
- [x] Deliver via PR that closes Issue #75 and enables auto-merge
