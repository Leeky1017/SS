# ISSUE-158

- Issue: #158
- Parent: #125
- Branch: task/158-stata18-smoke-suite
- PR: <fill-after-created>

## Goal
- Build reusable Stata 18 smoke-suite manifest + local runner with structured report, while keeping CI static gates strong when Stata cannot run.

## Status
- CURRENT: Manifest + runner + CI-safe validation tests implemented; ready for PR preflight and submission.

## Next Actions
- [x] Add smoke-suite manifest + schema (core subset).
- [x] Implement `ss run-smoke-suite` to write a structured report.
- [x] Add CI-safe tests to validate manifest (schema + fixtures + params).
- [x] Run `ruff check .` and `pytest -q`.
- [ ] Run `scripts/agent_pr_preflight.sh`, open PR, enable auto-merge.
- [ ] Update `PR:` link after creation.

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
