# ISSUE-280

- Issue: #280
- Parent: #125
- Branch: task/280-phase-4-10-finance-tk
- PR: <fill-after-created>

## Goal
- Make TK finance templates run on Stata 18 with fixtures, emit contract-compliant anchors, and follow unified style.

## Plan
- Add TK smoke-suite manifest (fixtures + params + deps).
- Run Stata 18 harness; fix failures to 0 failed within scope.
- Normalize anchors to `SS_EVENT|k=v` and unify style within TK templates.

## Status
- CURRENT: TK01–TK20 smoke suite passes (0 fail); anchors normalized; ready for repo validations + PR delivery.

## Next Actions
- [ ] Run `ruff check .`, `pytest -q`, `openspec validate --specs --strict --no-interactive`.
- [ ] Run `scripts/agent_pr_preflight.sh`, then commit + push.
- [ ] Create PR (Closes #280), enable auto-merge, verify merged.

## Decisions Made
- 2026-01-10: Replace legacy `SS_ERROR:`/`SS_ERR:`/`SS_WARNING:` anchors with `SS_RC|...` (warn/fail) and ensure fail-fast paths emit `SS_TASK_END|...|status=fail` via per-template `ss_fail_TKxx`.
- 2026-01-10: Normalize graph outputs to `type=graph` (header + `SS_OUTPUT_FILE`) within TK01–TK20.

## Errors Encountered
- 2026-01-10: Multiple TK templates initially failed Stata 18 harness (missing user packages, invalid merges, xtset edge cases); fixed iteratively until 0 fail (see smoke suite reports in Rulebook evidence).

## Runs
### 2026-01-10 10:45 setup (issue/worktree)
- Command:
  - `gh issue create -t "[PHASE-4.10] TK: Stata 18 audit + anchor normalization (TK01-TK20)" -b "<body omitted>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "280" "phase-4-10-finance-tk"`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/280`
  - `Worktree created: .worktrees/issue-280-phase-4-10-finance-tk`
  - `Branch: task/280-phase-4-10-finance-tk`
- Evidence: n/a

### 2026-01-10 10:50 venv (install dev deps)
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output: `Successfully installed ... ss-0.0.0`
- Evidence: `.venv/`

### 2026-01-10 10:52 smoke-suite manifest added
- Command: (file added)
- Key output: `assets/stata_do_library/smoke_suite/manifest.issue-280.tk01-tk20.1.0.json`
- Evidence: `assets/stata_do_library/smoke_suite/manifest.issue-280.tk01-tk20.1.0.json`

### 2026-01-10 12:38 smoke-suite rerun11 (post-anchor normalization)
- Command:
  - `. .venv/bin/activate && python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-280.tk01-tk20.1.0.json --report-path rulebook/tasks/issue-280-phase-4-10-finance-tk/evidence/smoke_suite_report.issue-280.rerun11.json --timeout-seconds 300`
- Key output:
  - `summary: {'passed': 20}`
  - `failed: 0`
- Evidence:
  - `rulebook/tasks/issue-280-phase-4-10-finance-tk/evidence/smoke_suite_report.issue-280.rerun11.json`

### 2026-01-10 12:40 validations (ruff/pytest/openspec)
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `ruff: All checks passed!`
  - `pytest: 162 passed, 5 skipped`
  - `openspec: Totals: 25 passed, 0 failed`
- Evidence: n/a
