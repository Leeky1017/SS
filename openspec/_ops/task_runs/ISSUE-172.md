# ISSUE-172

- Issue: #172
- Branch: task/172-p44-p45-tb-tc-td-te-audit
- PR: https://github.com/Leeky1017/SS/pull/180

## Plan
- Add TB/TC/TD/TE smoke-suite manifest (fixtures + params + deps).
- Run Stata 18 harness and fix failures to 0 fail.
- Normalize anchors to pipe-delimited `SS_*|k=v` (remove colon formats).

## Runs
### 2026-01-08 venv + deps
- Command: `python3 -m venv .venv && . .venv/bin/activate && pip install -e '.[dev]'`
- Key output: `Successfully installed ... ruff ... pytest ...`
- Evidence: `.venv/`

### 2026-01-08 Stata 18 smoke suite (issue-172 TB/TC/TD/TE)
- Command: `. .venv/bin/activate && python -m src.cli run-smoke-suite --manifest assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json --report-path /tmp/ss-issue-172-report2.json --timeout-seconds 300`
- Key output: `summary {'passed': 37}`
- Evidence: `assets/stata_do_library/smoke_suite/manifest.issue-172.tb-tc-td-te.1.0.json`, `/tmp/ss-issue-172-report2.json`

### 2026-01-08 lint + tests + openspec validate
- Command:
  - `. .venv/bin/activate && ruff check .`
  - `. .venv/bin/activate && pytest -q`
  - `. .venv/bin/activate && openspec validate --specs --strict --no-interactive`
- Key output:
  - `ruff`: `All checks passed!`
  - `pytest`: `131 passed, 5 skipped`
  - `openspec`: `Totals: 20 passed, 0 failed`
- Evidence: CI-safe local verification (see command outputs above)

### 2026-01-08 PR preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: preflight output in terminal
