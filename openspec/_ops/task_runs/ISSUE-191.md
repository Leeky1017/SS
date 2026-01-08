# ISSUE-191

- Issue: #191
- Branch: task/191-p5-4-descriptive-tb-tc
- PR: <fill-after-created>

## Goal
- Enhance TB02-TB10 + TC01-TC10 templates with best practices, fewer external dependencies, stronger error handling, and bilingual comments.

## Status
- CURRENT: Implement template/meta upgrades; run `ruff` + `pytest`; open PR with auto-merge.

## Next Actions
- [ ] Update task card metadata (Issue field)
- [ ] Enhance TB02-TB10 (best practices + error handling; reduce SSC where feasible)
- [ ] Enhance TC01-TC10 (best practices + error handling)
- [ ] Run `ruff check .` + `pytest -q`; record evidence
- [ ] Run `scripts/agent_pr_preflight.sh`; open PR; enable auto-merge; update `PR:` link

## Decisions Made
- 2026-01-08 Prefer “warn + degrade gracefully” over “hard fail” for optional visualization helpers when a built-in fallback exists.

## Errors Encountered
- (none yet)

## Runs
### 2026-01-08 setup
- Command:
  - `gh issue create -t "[PHASE-5.4] Template enhancement: Descriptive TB/TC" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 191 p5-4-descriptive-tb-tc`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/191`
  - `Worktree created: .worktrees/issue-191-p5-4-descriptive-tb-tc`

### 2026-01-08 templates + meta enhancements (TB/TC)
- Command:
  - `rg -n '"'"'\"source\"\\s*:\\s*\"ssc\"'"'"' assets/stata_do_library/do/meta -g 'TB*.meta.json' -g 'TC*.meta.json'`
  - `git status -sb`
- Key output:
  - `TB06/TB07/TB09: SSC plotting deps removed from meta; templates add built-in fallbacks`
  - `TB02/TB03/TB04: meta inputs normalized to data.csv required`

### 2026-01-08 venv + lint + tests
- Command:
  - `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `ruff: All checks passed!`
  - `pytest: FAILED tests/test_smoke_suite_manifest.py (TB06 dependency mismatch)`

### 2026-01-08 fix smoke-suite manifest deps (TB06/TB07/TB09) + rerun tests
- Command:
  - `rg -n '"'"'TB06|TB07|TB09|heatplot|vioplot|spineplot'"'"' assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json`
  - `.venv/bin/pytest -q`
- Key output:
  - `pytest: 136 passed, 5 skipped`
- Evidence:
  - `assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json`
