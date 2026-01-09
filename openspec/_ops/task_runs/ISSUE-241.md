# ISSUE-241
- Issue: #241
- Branch: task/241-p4-7-causal-tg
- PR: https://github.com/Leeky1017/SS/pull/249

## Plan
- Run Stata 18 smoke suite for TG01–TG25
- Fix runtime failures + anchor normalization
- Re-run to 0 fail and record evidence

## Runs
### 2026-01-09 Stata SSC deps install
- Command: `stata /e do /tmp/ss-issue-241-stata-deps/install.do`
- Key output: Installed `psmatch2`, `cem`, `rbounds`, `rdrobust`, `rddensity`, `ivreg2`, `ranktest`, `xtivreg2`, `synth`, `csdid`, `drdid`, `reghdfe`, `did_multiplegt`, `mtefe` (plus `ftools` for `reghdfe`)
- Evidence: `/tmp/ss-issue-241-stata-deps/install.log`, `/tmp/ss-issue-241-stata-deps2/install_ftools.log`

### 2026-01-09 Stata 18 smoke suite (TG01–TG25)
- Command: `python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-241.tg01-tg25.1.0.json --report-path rulebook/tasks/issue-241-p4-7-causal-tg/evidence/smoke_suite_report.issue-241.post-anchors.json --timeout-seconds 600`
- Key output: `summary.passed=25` (0 fail)
- Evidence: `rulebook/tasks/issue-241-p4-7-causal-tg/evidence/smoke_suite_report.issue-241.post-anchors.json`

### 2026-01-09 Local checks
- Command: `ruff check .`
- Key output: `All checks passed!`
- Command: `pytest -q`
- Key output: `159 passed, 5 skipped`

### 2026-01-09 Closeout
- Key output: PR https://github.com/Leeky1017/SS/pull/249 merged; task card acceptance + completion backfilled
