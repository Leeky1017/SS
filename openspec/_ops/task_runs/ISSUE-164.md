# ISSUE-164

- Issue: #164
- Parent: #125
- Branch: task/164-p4-2-core-t21-t50
- PR: <fill-after-created>

## Goal
- Phase 4.2: Make templates `T21`–`T50` run on Stata 18 with fixtures, emit contract-compliant anchors, and follow unified style.

## Status
- CURRENT: Worktree ready; preparing Phase 4.2 harness manifest and first Stata 18 run.

## Next Actions
- [ ] Create a Phase 4.2 smoke-suite manifest for `T21`–`T50`.
- [ ] Run Stata 18 batch harness and save a structured report.
- [ ] Fix runtime failures and iterate until 0 `fail`.
- [ ] Remove legacy `SS_*:` anchors; keep only `SS_EVENT|k=v` format.
- [ ] Run `ruff check .` + `pytest -q`, then open PR with auto-merge.

## Runs
### 2026-01-08 issue + worktree
- Command:
  - `gh issue create -t "[PHASE-4.2] Template Code Quality Audit: Core T21–T50" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "164" "p4-2-core-t21-t50"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/164`
  - `Worktree created: .worktrees/issue-164-p4-2-core-t21-t50`

### 2026-01-08 env + deps
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output:
  - `Successfully installed ... ruff ... pytest ... mypy ...`

### 2026-01-08 smoke suite run (Phase 4.2 core, Stata 18)
- Command:
  - `. .venv/bin/activate && python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.phase-4.2-core-t21-t50.1.0.json --report-path /tmp/ss-phase-4.2-core-t21-t50.rerun1.json --timeout-seconds 600`
- Key output:
  - `report_path=/tmp/ss-phase-4.2-core-t21-t50.rerun1.json`
  - `summary: {'passed': 30}`

### 2026-01-08 anchors + style normalization (Phase 4.2 scope)
- Command:
  - `rg -n 'display \"SS_[A-Z0-9_]+:' assets/stata_do_library/do/T{21..50}_*.do`
- Key output:
  - `0 matches`

### 2026-01-08 smoke suite re-run (post-anchor normalization)
- Command:
  - `. .venv/bin/activate && python3 -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.phase-4.2-core-t21-t50.1.0.json --report-path /tmp/ss-phase-4.2-core-t21-t50.rerun2-anchors.json --timeout-seconds 600`
- Key output:
  - `report_path=/tmp/ss-phase-4.2-core-t21-t50.rerun2-anchors.json`
  - `summary: {'passed': 30}`

### 2026-01-08 do-file lint (contract v1.1)
- Command:
  - `. .venv/bin/activate && python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do --output /tmp/do_lint_report_issue164.rerun.json`
- Key output:
  - `RESULT: [OK] PASSED`
  - `通过文件数:   310`
- Evidence:
  - `/tmp/do_lint_report_issue164.rerun.json`

### 2026-01-08 repo checks
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
- Key output:
  - `ruff`: `All checks passed!`
  - `pytest`: `124 passed, 5 skipped`

### 2026-01-08 pr preflight
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
