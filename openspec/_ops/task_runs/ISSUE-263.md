# ISSUE-263
- Issue: #263
- Branch: `task/263-p58-timeseries-th`
- PR: <fill-after-created>

## Plan
- Upgrade TH templates with best-practice review + bilingual comments.
- Replace SSC deps where feasible; strengthen error handling/diagnostics.
- Record lint/test evidence and ship via auto-merge.

## Runs
### 2026-01-10 00:23 bootstrap
- Command: `git status --porcelain=v1`
- Key output: `M assets/stata_do_library/do/TH*.do` (+ meta/docs/smoke_suite + task card + run log + rulebook task)
- Evidence: `.worktrees/issue-263-p58-timeseries-th/openspec/_ops/task_runs/ISSUE-263.md`

### 2026-01-10 00:23 do-lint (TH only)
- Command: `for f in assets/stata_do_library/do/TH*.do; do python3 assets/stata_do_library/DO_LINT_RULES.py --file "$f"; done`
- Key output: `TH01_dfgls ... TH15_sspace: RESULT: [OK] PASSED (all 13 TH templates)`
- Evidence: `/tmp/do_lint_TH*.json`

### 2026-01-10 00:24 ruff
- Command: `python -m venv /tmp/ss-venv && /tmp/ss-venv/bin/pip install -e '.[dev]' && /tmp/ss-venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: `/tmp/ss-venv`

### 2026-01-10 00:24 pytest
- Command: `/tmp/ss-venv/bin/python -m pytest -q`
- Key output: `159 passed, 5 skipped in 7.79s`
- Evidence: `/tmp/ss-venv`
