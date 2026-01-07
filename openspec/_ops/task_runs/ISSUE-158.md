# ISSUE-158

- Issue: #158
- Parent: #125
- Branch: task/158-stata18-smoke-suite
- PR: https://github.com/Leeky1017/SS/pull/159

## Goal
- Build reusable Stata 18 smoke-suite manifest + local runner with structured report, while keeping CI static gates strong when Stata cannot run.

## Status
- CURRENT: PR opened; required checks green. Next: enable auto-merge and wait for merge-serial.

## Next Actions
- [x] Add smoke-suite manifest + schema (core subset).
- [x] Implement `ss run-smoke-suite` to write a structured report.
- [x] Add CI-safe tests to validate manifest (schema + fixtures + params).
- [x] Run `ruff check .` and `pytest -q`.
- [x] Run `scripts/agent_pr_preflight.sh` and open PR.
- [x] Update `PR:` link after creation.
- [ ] Enable auto-merge and watch required checks until merged.

## Runs
### 2026-01-07 issue + worktree
- Command:
  - `gh issue create -t "[PHASE-3] Stata 18 smoke suite + evidence harness" -b "..."`
  - `scripts/agent_worktree_setup.sh "158" "stata18-smoke-suite"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/158`
  - `Worktree created: .worktrees/issue-158-stata18-smoke-suite`

### 2026-01-07 env + deps
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff ... pytest ... mypy ...`

### 2026-01-07 lint + tests
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
  - `. .venv/bin/activate && mypy`
- Key output:
  - `ruff`: `All checks passed!`
  - `pytest`: `123 passed, 5 skipped`
  - `mypy`: `Success: no issues found in 94 source files`

### 2026-01-07 smoke suite run (Stata 18)
- Command:
  - `. .venv/bin/activate && python -m src.cli run-smoke-suite --report-path /tmp/ss-smoke-suite-report2.json`
- Key output:
  - `report_path=/tmp/ss-smoke-suite-report2.json`
  - `summary: {'passed': 7}`

### 2026-01-07 openspec validate (strict)
- Command:
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Totals: 20 passed, 0 failed`

### 2026-01-07 pr preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`

### 2026-01-07 PR status (required checks)
- Command:
  - `gh pr view 159 --json url,state,mergeStateStatus,autoMergeRequest,statusCheckRollup`
- Key output:
  - `url=https://github.com/Leeky1017/SS/pull/159`
  - `state=OPEN mergeStateStatus=CLEAN autoMergeRequest=null`
  - `ci`: `SUCCESS`
  - `openspec-log-guard`: `SUCCESS`
  - `merge-serial`: `SUCCESS`
