# ISSUE-240

- Issue: #240
- Parent: #125
- Branch: task/240-panel-advanced-tf01-tf14
- PR: <fill-after-created>

## Plan
- Add TF smoke-suite manifest (fixtures + params + deps).
- Run Stata 18 harness and fix failures to 0 fail.
- Normalize anchors within scope to `SS_EVENT|k=v` (remove colon formats).

## Runs

### 2026-01-09 12:48 venv + deps
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output: `Successfully installed ...`
- Evidence: `.venv/`

### 2026-01-09 12:49 smoke suite (initial) — WSL interop decode crash
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-240.tf01-tf14.1.0.json --report-path /tmp/ss-smoke-suite-issue240-tf.json --timeout-seconds 600`
- Key output: `UnicodeDecodeError` in `src/infra/stata_cmd.py` (cmd.exe output decode)
- Evidence: terminal output (traceback)

### 2026-01-09 13:11 smoke suite (post-fixes) — 0 failed
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-240.tf01-tf14.1.0.json --report-path /tmp/ss-smoke-suite-issue240-tf.json --timeout-seconds 600`
- Key output: `summary {'missing_deps': 3, 'passed': 10}`
- Evidence: `/tmp/ss-smoke-suite-issue240-tf.json`

### 2026-01-09 21:08 Stata package install attempt (SSC)
- Command: `"/mnt/c/Program Files/Stata18/StataMP-64.exe" /e do /tmp/ss-issue240-stata-install/install.do`
- Key output:
  - Installed: `xtcsd`, `xttest3`, `xtscc`, `xtabond2`
  - Not found at SSC: `xtserial`, `xthreg`, `pvar`
- Evidence: `/tmp/ss-issue240-stata-install/install.log`

### 2026-01-09 21:15 python lint + tests + openspec validate
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
  - `. .venv/bin/activate && openspec validate --specs --strict --no-interactive`
- Key output:
  - `ruff`: `All checks passed!`
  - `pytest`: `152 passed, 5 skipped`
  - `openspec`: `Totals: 25 passed, 0 failed`
- Evidence: CI-safe local verification (see command outputs above)

### 2026-01-09 21:16 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`; `OK: no hard dependencies found in execution plan`
- Evidence: terminal output
