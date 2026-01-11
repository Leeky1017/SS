# ISSUE-353

- Issue: #353
- Branch: `task/353-p4-13-spatial-output-tn-to`
- PR: <fill-after-created>

## Plan
- Add a dedicated smoke-suite manifest for TN01–TN10 + TO01–TO08 and run Stata 18 batch harness.
- Fix all runtime failures and normalize anchors to `SS_EVENT|k=v` (+ `SS_RC` for warn/fail).
- Record evidence in this run log and close out Phase 4.13 task card.

## Runs
### 2026-01-11 00:00 UTC bootstrap
- Command:
  - `gh issue create -t "[PHASE-4.13] Spatial+Output templates TN/TO: Stata18 0-fail + anchors" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 353 p4-13-spatial-output-tn-to`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/353`
  - `Worktree created: .worktrees/issue-353-p4-13-spatial-output-tn-to`

### 2026-01-11 02:10 UTC smoke-suite rerun01 (baseline)
- Command: `SS_LLM_PROVIDER=local .venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-353.tn01-tn10.to01-to08.1.0.json --report-path rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun01.json`
- Key output: `summary: failed=18`
- Evidence: `rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun01.json`

### 2026-01-11 02:30 UTC smoke-suite rerun02
- Command: `SS_LLM_PROVIDER=local .venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-353.tn01-tn10.to01-to08.1.0.json --report-path rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun02.json`
- Key output: `summary: failed=14 passed=4`
- Evidence: `rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun02.json`

### 2026-01-11 02:50 UTC smoke-suite rerun03
- Command: `SS_LLM_PROVIDER=local .venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-353.tn01-tn10.to01-to08.1.0.json --report-path rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun03.json`
- Key output: `summary: failed=1 passed=17`
- Evidence: `rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun03.json`

### 2026-01-11 02:55 UTC smoke-suite rerun04 (0 fail)
- Command: `SS_LLM_PROVIDER=local .venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-353.tn01-tn10.to01-to08.1.0.json --report-path rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun04.json`
- Key output: `summary: passed=18`
- Evidence: `rulebook/tasks/issue-353-p4-13-spatial-output-tn-to/evidence/smoke_suite_report.issue-353.rerun04.json`

### 2026-01-11 03:02 UTC lint + tests
- Command: `.venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: (stdout)
- Command: `.venv/bin/pytest -q`
- Key output: `183 passed, 5 skipped in 9.24s`
- Evidence: (stdout)
