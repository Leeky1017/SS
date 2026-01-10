# ISSUE-317
- Issue: #317 https://github.com/Leeky1017/SS/issues/317
- Branch: task/317-prod-e2e-r042
- PR: https://github.com/Leeky1017/SS/pull/319

## Plan
- Remove worker fake-runner fallback; fail fast on missing `SS_STATA_CMD`.
- Migrate tests to injected `tests/**` fake runner.
- Run `ruff` + `pytest` and open PR with auto-merge.

## Runs
### 2026-01-10 Setup: venv + deps
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output: `Successfully installed ... ss-0.0.0 ... ruff ... pytest ... pydantic ...`

### 2026-01-10 Validation: ruff + pytest
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Command: `.venv/bin/pytest -q`
- Key output: `170 passed, 5 skipped`

### 2026-01-10 Preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs` / `OK: no hard dependencies found in execution plan`

### 2026-01-10 PR: create + auto-merge
- Command: `gh pr create ...`
- Key output: `https://github.com/Leeky1017/SS/pull/319`
- Command: `gh pr merge --auto --squash 319`
- Key output: `will be automatically merged via squash when all requirements are met`

### 2026-01-10 Merge: keep up-to-date + verify mergedAt
- Command: `git fetch origin main && git rebase origin/main && git push --force-with-lease`
- Command: `gh run rerun 20875339135` (rerun cancelled `merge-serial` for current head)
- Command: `gh pr checks --watch 319`
- Command: `gh pr view 319 --json state,mergedAt`
- Key output: `state=MERGED` / `mergedAt=2026-01-10T08:13:50Z`

### 2026-01-10 Rulebook: archive task
- Command: `rulebook_task_archive issue-317-prod-e2e-r042 (skipValidation=true)`
- PR: https://github.com/Leeky1017/SS/pull/325
