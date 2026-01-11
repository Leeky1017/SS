# ISSUE-354

- Issue: #354
- Parent: #125
- Branch: task/354-phase-4-14-panel-hlm-tp-tq
- PR: <fill-after-created>

## Goal
- Audit TP01–TP15 + TQ01–TQ12: Stata 18 smoke-suite 0 fail, anchors `SS_EVENT|k=v`, unified style and explicit warn/fail diagnostics.

## Plan
- Add TP/TQ smoke-suite manifest (fixtures + params + deps) and run harness.
- Fix runtime failures; normalize anchors to `SS_EVENT|k=v` (+ `SS_RC` for warn/fail) within TP/TQ scope.
- Record evidence in Rulebook task and link reports here.

## Runs
### 2026-01-11 00:10 setup (issue/worktree)
- Command:
  - `gh issue create -t "[PHASE-4.14] TP/TQ: Stata 18 audit + anchors (TP01-TP15, TQ01-TQ12)" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "354" "phase-4-14-panel-hlm-tp-tq"`
- Key output:
  - `Issue: https://github.com/Leeky1017/SS/issues/354`
  - `Worktree created: .worktrees/issue-354-phase-4-14-panel-hlm-tp-tq`
  - `Branch: task/354-phase-4-14-panel-hlm-tp-tq`
- Evidence: n/a

### 2026-01-11 10:57 smoke suite (rerun6, all pass)
- Command: `. .venv/bin/activate && SS_LLM_PROVIDER=openai_compatible SS_LLM_API_KEY=dummy python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-354.tp01-tp15.tq01-tq12.1.0.json --report-path rulebook/tasks/issue-354-phase-4-14-panel-hlm-tp-tq/evidence/smoke_suite_report.issue-354.rerun6.json --timeout-seconds 600`
- Key output:
  - `summary: {"passed": 27}`
  - `TQ03: vecrank r(498) collinearity handled (no r() in log; outputs produced)`
- Evidence: `rulebook/tasks/issue-354-phase-4-14-panel-hlm-tp-tq/evidence/smoke_suite_report.issue-354.rerun6.json`

### 2026-01-11 11:06 anchors + style (TP01–TP15, TQ01–TQ12)
- Key changes:
  - Anchors normalized: removed legacy `SS_*:...` variants; keep `SS_EVENT|k=v` + `SS_RC` warn/fail context.
  - Failure paths emit `SS_TASK_END|...|status=fail` before `exit`.
- Evidence: see `git diff` + rerun7 report below.

### 2026-01-11 11:06 smoke suite (rerun7, post-anchor, all pass)
- Command: `. .venv/bin/activate && SS_LLM_PROVIDER=openai_compatible SS_LLM_API_KEY=dummy python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-354.tp01-tp15.tq01-tq12.1.0.json --report-path rulebook/tasks/issue-354-phase-4-14-panel-hlm-tp-tq/evidence/smoke_suite_report.issue-354.rerun7.post_anchor.json --timeout-seconds 600`
- Key output: `summary: {"passed": 27}`
- Evidence: `rulebook/tasks/issue-354-phase-4-14-panel-hlm-tp-tq/evidence/smoke_suite_report.issue-354.rerun7.post_anchor.json`

### 2026-01-11 11:08 local checks
- Command: `. .venv/bin/activate && ruff check .`
- Key output: `All checks passed!`
- Evidence: n/a

### 2026-01-11 11:08 local tests
- Command: `. .venv/bin/activate && pytest -q`
- Key output: `184 passed, 5 skipped`
- Evidence: n/a

### 2026-01-11 11:09 openspec validate
- Command: `. .venv/bin/activate && openspec validate --specs --strict --no-interactive`
- Key output: `Totals: 28 passed, 0 failed`
- Evidence: n/a
