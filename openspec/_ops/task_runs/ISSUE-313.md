# ISSUE-313
- Issue: #313
- Branch: task/313-ssc-stcure-deps
- PR: <fill-after-created>

## Plan
- Add Stata SSC dependency list for remote servers
- Remove TI09 external dep (`stcure`) and rerun TI/TJ smoke-suite

## Runs
### 2026-01-10 bootstrap
- Command: `rulebook task create issue-313-ssc-stcure-deps && rulebook task validate issue-313-ssc-stcure-deps`
- Key output: `Task issue-313-ssc-stcure-deps is valid (warnings: no spec files found)`
- Evidence: `rulebook/tasks/issue-313-ssc-stcure-deps/`

### 2026-01-10 locate stcure
- Command: `"/mnt/c/Program Files/Stata18/StataMP-64.exe" /e do "/tmp/ss-locate-stcure-issue-313/locate_stcure.do"`
- Key output: `SS_LOCATE_NOT_FOUND|pkg=stcure` (checked Stata Journal net + stb)
- Evidence: `rulebook/tasks/issue-313-ssc-stcure-deps/evidence/stata_locate_stcure.log`

### 2026-01-10 ssc install stcure (failed)
- Command: `"/mnt/c/Program Files/Stata18/StataMP-64.exe" /e do "/tmp/ss-install-stcure-issue-313/install_stcure.do"`
- Key output: `ssc install: "stcure" not found at SSC` (r(601))
- Evidence: `rulebook/tasks/issue-313-ssc-stcure-deps/evidence/stata_ssc_install_stcure.log`

### 2026-01-10 TI09 dep removal + smoke-suite
- Command: `/tmp/ss-venv/bin/python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-271.ti01-ti11.tj01-tj06.1.0.json --report-path rulebook/tasks/issue-313-ssc-stcure-deps/evidence/smoke_suite_report.issue-313.ti-tj.json --timeout-seconds 30`
- Key output: `summary {'passed': 17}`
- Evidence: `rulebook/tasks/issue-313-ssc-stcure-deps/evidence/smoke_suite_report.issue-313.ti-tj.json`

### 2026-01-10 local checks
- Command: `/tmp/ss-venv/bin/ruff check .`
- Key output: `All checks passed!`
- Evidence: (stdout)

### 2026-01-10 tests
- Command: `/tmp/ss-venv/bin/pytest -q`
- Key output: `169 passed, 5 skipped`
- Evidence: (stdout)
