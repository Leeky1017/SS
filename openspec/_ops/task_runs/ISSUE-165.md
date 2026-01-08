# ISSUE-165

- Issue: #165
- Branch: task/165-p4-3-data-prep-ta
- PR: https://github.com/Leeky1017/SS/pull/175

## Goal
- Make TA01-TA14 (data prep) templates runnable under the Stata 18 smoke-suite harness with fixtures; standardize anchors + style; fail fast on missing SSC deps.

## Status
- CURRENT: TA01-TA14 anchors/deps normalized; do-lint + ruff + pytest are green; next run smoke-suite (Stata 18) and open PR.

## Next Actions
- [x] Add smoke-suite entries + fixtures for TA01-TA14
- [x] Normalize TA01-TA14 anchors + deps checks; fix runtime errors found in fixtures runs
- [x] Run `ruff` + `pytest`; record evidence
- [ ] Run smoke-suite for TA01-TA14 (Stata 18) and record results
- [ ] Open PR with auto-merge; sync + cleanup worktree after merge

## Decisions Made
- 2026-01-08 Anchor normalization will remove legacy `SS_*:` variants within TA01-TA14 and emit `SS_RC|...` for failures/warnings.

## Errors Encountered
- 2026-01-08 Controlplane was dirty due to unrelated WIP; stashed to proceed with isolated worktree.
- 2026-01-08 `ruff` not available in system Python (PEP 668); created `.venv` to run `ruff`/`pytest` locally.
- 2026-01-08 Smoke suite crashed parsing missing deps (`NoneType.strip`); hardened `_extract_missing_deps` to skip non-string matches.

## Runs
### 2026-01-08 09:15 setup
- Command:
  - `gh issue create -t "[ROUND-01-TA-A] DO-LIB-OPT-P4.3: data prep templates TA01-TA14 Stata18 audit" -b "<body>"`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh 165 p4-3-data-prep-ta`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/165`
  - `Worktree created: .worktrees/issue-165-p4-3-data-prep-ta`

### 2026-01-08 09:42 smoke-suite manifest (TA01-TA14)
- Command:
  - `python3 -m json.tool assets/stata_do_library/smoke_suite/manifest.1.0.json > /tmp/manifest_165.json`
- Key output:
  - `manifest.1.0.json updated with TA02-TA14 entries`
- Evidence:
  - `assets/stata_do_library/smoke_suite/manifest.1.0.json`

### 2026-01-08 10:30 do-library lint
- Command:
  - `python3 assets/stata_do_library/DO_LINT_RULES.py --path assets/stata_do_library/do --output /tmp/do_lint_report_165.json`
- Key output:
  - `RESULT: [OK] PASSED`
  - `JSON report saved to: /tmp/do_lint_report_165.json`
- Evidence:
  - `/tmp/do_lint_report_165.json`

### 2026-01-08 10:32 venv + lint + tests
- Command:
  - `python3 -m venv .venv && .venv/bin/pip install -e ".[dev]"`
  - `.venv/bin/ruff check .`
  - `.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `123 passed, 5 skipped`

### 2026-01-08 13:34 smoke-suite (Stata 18): TA01-TA14
- Command:
  - `.venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.1.0.json --report-path /tmp/smoke_suite_report_165.json --timeout-seconds 300`
- Key output:
  - `EXIT=0`
  - `TA01-TA14: all passed (0 fail)`
- Evidence:
  - `/tmp/smoke_suite_report_165.json`

### 2026-01-08 13:36 deliver: preflight + PR
- Command:
  - `scripts/agent_pr_preflight.sh`
  - `gh pr create --title "... (#165)" --body "Closes #165 ..."`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
  - `https://github.com/Leeky1017/SS/pull/175`
