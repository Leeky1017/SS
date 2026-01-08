# ISSUE-192

- Issue: #192
- Branch: task/192-p5-5-regression-td-te
- PR: https://github.com/Leeky1017/SS/pull/199

## Goal
- Enhance TD01-TD06, TD10, TD12 + TE01-TE10 templates with regression best practices/diagnostics, fewer SSC dependencies where feasible, stronger error handling, and bilingual comments.

## Status
- CURRENT: PR opened; enable auto-merge; wait for required checks to pass and merge.

## Next Actions
- [x] Update task card metadata (Issue field)
- [x] Remove/reduce SSC deps where feasible (TD01/TD02/TE05) and justify remaining (TE08)
- [x] Add best-practice review record + bilingual notes across TD/TE templates
- [x] Strengthen validation + error handling for common regression failures
- [x] Run `ruff check .` + `pytest -q`; record evidence
- [x] Run `scripts/agent_pr_preflight.sh`; open PR; enable auto-merge; update `PR:` link
- [ ] Wait for checks; merge PR

## Decisions Made
- 2026-01-08 Replace SSC table export (`estout/esttab`) with matrix-based CSV export; keep SSC model commands only when no base-Stata equivalent exists.

## Errors Encountered
- (none yet)

## Runs
### 2026-01-08 setup
- Command:
  - `gh issue create -t "[PHASE-5.5] Template enhancement: Regression TD/TE" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 192 p5-5-regression-td-te`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/192`
  - `Worktree created: .worktrees/issue-192-p5-5-regression-td-te`

### 2026-01-08 templates + meta enhancements (TD/TE)
- Command:
  - `rg -n '"'"'\"source\"\\s*:\\s*\"ssc\"'"'"' assets/stata_do_library/do/meta -g 'TD*.meta.json' -g 'TE*.meta.json'`
  - `git status -sb`
- Key output:
  - `TD01: reghdfe → xtreg (remove SSC dep in meta)`
  - `TD02: estout removed; CSV export via _b/_se; keep reghdfe SSC dep`
  - `TE05: twopm removed; two-part via logit + glm (built-in)`

### 2026-01-08 venv + lint + tests (initial failure)
- Command:
  - `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `ruff: All checks passed!`
  - `pytest: FAILED tests/test_smoke_suite_manifest.py (TD01 dependency mismatch)`

### 2026-01-08 fix smoke-suite manifest deps (TD01/TD02/TE05) + rerun tests
- Command:
  - `rg -n '"'"'TD01|TD02|TE05|reghdfe|estout|twopm'"'"' assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json`
  - `.venv/bin/pytest -q`
- Key output:
  - `pytest: 136 passed, 5 skipped`
- Evidence:
  - `assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json`

### 2026-01-08 rebase + preflight + PR
- Command:
  - `git fetch origin && git rebase origin/main`
  - `scripts/agent_pr_preflight.sh`
  - `git push -u origin HEAD`
  - `gh pr create ...`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/199`
