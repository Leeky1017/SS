# ISSUE-355
- Issue: #355
- Branch: task/355-phase-4-15-bayes-ml-text-viz-tr-tu
- PR: <fill-after-created>

## Plan
- Add TR–TU smoke-suite manifest(s) (fixtures + params + deps).
- Run Stata 18 harness; fix failures to 0 failed within scope.
- Normalize anchors to `SS_EVENT|k=v` and unify template style.

## Runs
### 2026-01-11 00:00 Setup worktree
- Command:
  - `scripts/agent_worktree_setup.sh "355" "phase-4-15-bayes-ml-text-viz-tr-tu"`
- Key output:
  - `Worktree created: .worktrees/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu`
  - `Branch: task/355-phase-4-15-bayes-ml-text-viz-tr-tu`
- Evidence:
  - (terminal transcript)

### 2026-01-11 00:00 Create Rulebook task (spec-first)
- Command:
  - `rulebook task create issue-355-phase-4-15-bayes-ml-text-viz-tr-tu`
  - `rulebook task validate issue-355-phase-4-15-bayes-ml-text-viz-tr-tu`
- Key output:
  - `✅ Task issue-355-phase-4-15-bayes-ml-text-viz-tr-tu is valid`
- Evidence:
  - `rulebook/tasks/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu/`

### 2026-01-11 11:07 Build smoke-suite manifests
- Command:
  - `python3 -m src.cli run-smoke-suite --help` (schema sanity)
- Key output:
  - Created manifests (Package A/B):
    - `assets/stata_do_library/smoke_suite/manifest.issue-355.tr01-tr10.ts01-ts12.1.0.json`
    - `assets/stata_do_library/smoke_suite/manifest.issue-355.tt01-tt10.tu01-tu14.1.0.json`
- Evidence:
  - `assets/stata_do_library/smoke_suite/manifest.issue-355.tr01-tr10.ts01-ts12.1.0.json`
  - `assets/stata_do_library/smoke_suite/manifest.issue-355.tt01-tt10.tu01-tu14.1.0.json`

### 2026-01-11 11:09 Smoke suite (Package A: TR01–TR10 + TS01–TS12) — PASS
- Command:
  - `SS_LLM_PROVIDER=offline SS_STATA_CMD='/mnt/c/Program Files/Stata18/StataMP-64.exe' SS_JOBS_DIR=/tmp/ss_jobs_issue355_a6 python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-355.tr01-tr10.ts01-ts12.1.0.json --report-path rulebook/tasks/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu/evidence/smoke_suite_report.issue-355.a.rerun6.json --timeout-seconds 300`
- Key output:
  - `summary={'passed': 22}`
- Evidence:
  - `rulebook/tasks/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu/evidence/smoke_suite_report.issue-355.a.rerun6.json`

### 2026-01-11 11:25 Smoke suite (Package B: TT01–TT10 + TU01–TU14) — PASS
- Command:
  - `SS_LLM_PROVIDER=offline SS_STATA_CMD='/mnt/c/Program Files/Stata18/StataMP-64.exe' SS_JOBS_DIR=/tmp/ss_jobs_issue355_b4 python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-355.tt01-tt10.tu01-tu14.1.0.json --report-path rulebook/tasks/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu/evidence/smoke_suite_report.issue-355.b.rerun4.json --timeout-seconds 300`
- Key output:
  - `summary={'passed': 24}`
- Evidence:
  - `rulebook/tasks/issue-355-phase-4-15-bayes-ml-text-viz-tr-tu/evidence/smoke_suite_report.issue-355.b.rerun4.json`

### 2026-01-11 11:30 Anchor normalization (TR–TU scope)
- Command:
  - `rg -n "SS_ERROR:|SS_ERR:" assets/stata_do_library/do/{TR,TS,TT,TU}*.do`
- Key output:
  - `0 matches` (all legacy `SS_*:` anchors removed in scope)
- Evidence:
  - (repository diff)

### 2026-01-11 11:40 Local checks
- Command:
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `ruff: All checks passed!`
  - `pytest: 184 passed, 5 skipped`
- Evidence:
  - (terminal transcript)
