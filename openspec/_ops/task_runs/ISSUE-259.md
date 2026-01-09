# ISSUE-259
- Issue: #259
- Branch: task/259-ops-e2e-verify
- PR: https://github.com/Leeky1017/SS/pull/264

## Goal
- Validate SS end-to-end v1 loop (redeem → upload → preview → draft preview/patch/confirm → run → artifacts download) using Claude Opus 4.5.

## Status
- CURRENT: E2E v1 loop validated end-to-end (including artifacts download) after fixes; ready to open PR + auto-merge.

## Next Actions
- [x] Restart API/worker and re-run v1 journey to `succeeded` with CSV inputs.
- [x] Run `ruff check .` and `pytest -q` (record outputs).
- [ ] Open PR (Closes #259) and enable auto-merge.

## Decisions Made
- 2026-01-09: Use Yunwu OpenAI-compatible proxy (`SS_LLM_PROVIDER=yunwu`) with Claude Opus 4.5 **versioned** model id; normalize legacy `claude-opus-4-5` alias to a working id.
- 2026-01-09: Fix `DoFileGenerator` to import CSV via `import delimited` (was `use` → r(609)).

## Errors Encountered
- 2026-01-09: `LLM_CALL_FAILED` (HTTP 503) when `SS_LLM_MODEL=claude-opus-4-5` (proxy reports no available channels for that alias).
- 2026-01-09: Worker run failed with `STATA_RETURN_CODE` (r(609)) because generated do-file used `use` on a `.csv`.

## Runs
### 2026-01-09 Setup: Issue + worktree
- Command:
  - `gh issue create -t "[OPS] SS: end-to-end verification + launch readiness" -b "..."`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "259" "ops-e2e-verify"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/259`
  - `Worktree created: .worktrees/issue-259-ops-e2e-verify`
  - `Branch: task/259-ops-e2e-verify`
- Evidence:
  - (this file)

### 2026-01-09 Setup: venv
- Command:
  - `python3 -m venv .venv && . .venv/bin/activate && pip install -e ".[dev]"`
- Key output:
  - `Successfully installed ... ss-0.0.0`
- Evidence:
  - N/A

### 2026-01-09 Runtime check: Local Stata batch mode
- Command:
  - `"/mnt/c/Program Files/Stata18/StataMP-64.exe" /e do ss_run.do`
- Key output:
  - `exit_code=0`
  - `ss_run.log created`
- Evidence:
  - Local smoke do-file (temp dir)

### 2026-01-09 E2E (attempt 1): Redeem + upload + preview
- Command:
  - `POST /v1/task-codes/redeem` (`task_code=tc_e2e_259_01`)
  - `POST /v1/jobs/{job_id}/inputs/upload` (CSV)
  - `GET /v1/jobs/{job_id}/inputs/preview`
- Key output:
  - `job_id=job_tc_65b5a60844350800` (token redacted)
  - `inputs/preview columns=[firm_id,year,ln_sales,policy,ln_assets,leverage,roa]`
- Evidence:
  - `/tmp/ss_e2e_panel_259.csv` (local)

### 2026-01-09 E2E (attempt 1): Draft preview fails on model alias
- Command:
  - `GET /v1/jobs/job_tc_65b5a60844350800/draft/preview`
- Key output:
  - `502 {"error_code":"LLM_CALL_FAILED",...}`
  - API logs show 503 from proxy: `No available channels for model claude-opus-4-5`
- Evidence:
  - API logs (local stdout)

### 2026-01-09 LLM debug: Enumerate available models
- Command:
  - `GET /v1/models` via OpenAI-compatible client
- Key output:
  - Available Opus 4.5 model id includes `claude-opus-4-5-20251101`
  - Direct call with `model=claude-opus-4-5-20251101` returns `OK`
- Evidence:
  - Local CLI output (redacted)

### 2026-01-09 E2E (attempt 1): Draft preview + patch + confirm succeeds
- Command:
  - Restart API/worker with `SS_LLM_PROVIDER=yunwu` and a working Opus 4.5 model id
  - `GET /v1/jobs/job_tc_65b5a60844350800/draft/preview`
  - `POST /v1/jobs/{job_id}/draft/patch` (set outcome/treatment/controls)
  - `POST /v1/jobs/{job_id}/confirm` (answer `analysis_goal`)
- Key output:
  - `draft_ready → queued`
  - Confirm missing `analysis_goal` blocks with `DRAFT_CONFIRM_BLOCKED`
- Evidence:
  - Job: `jobs/tc/job_tc_65b5a60844350800/job.json`

### 2026-01-09 E2E (attempt 1): Worker run fails on CSV `use` (r(609))
- Command:
  - Worker executes generated do-file
- Key output:
  - `STATA_RETURN_CODE` with `r(609)` (`use` cannot open CSV)
- Evidence:
  - `jobs/tc/job_tc_65b5a60844350800/runs/c1dd3484cda04a88983d1d7ae8e22046/artifacts/stata.do`
  - `jobs/tc/job_tc_65b5a60844350800/runs/c1dd3484cda04a88983d1d7ae8e22046/artifacts/stata.log`

### 2026-01-09 Fix (in progress): Model normalization + CSV import
- Command:
  - Update `src/config.py` to normalize `claude-opus-4-5` → `claude-opus-4-5-20251101`
  - Update `DoFileGenerator` to use `import delimited` for CSV
  - Add pytest regression coverage for CSV import do-file generation
- Key output:
  - Pending rerun of E2E journey to confirm `succeeded`
- Evidence:
  - Code changes in this branch

### 2026-01-09 E2E (attempt 2): Full loop succeeds (CSV)
- Command:
  - `POST /v1/task-codes/redeem` (`task_code=tc_e2e_259_03`)
  - `POST /v1/jobs/{job_id}/inputs/upload` (CSV)
  - `GET /v1/jobs/{job_id}/draft/preview`
  - `POST /v1/jobs/{job_id}/draft/patch` (set outcome/treatment/controls)
  - `POST /v1/jobs/{job_id}/confirm` (answer `analysis_goal`)
  - Poll `GET /v1/jobs/{job_id}` until `succeeded`
  - `GET /v1/jobs/{job_id}/artifacts` + download `ss_summary_table.csv` + `stata.do`
- Key output:
  - `job_id=job_tc_ddd14b6d5358d62b` (token redacted)
  - Job reached `succeeded`
  - Summary table: `N=60`, `k=7`
  - Generated do-file uses `import delimited using "inputs/...csv", clear varnames(1)`
- Evidence:
  - `jobs/tc/job_tc_ddd14b6d5358d62b/job.json`
  - `jobs/tc/job_tc_ddd14b6d5358d62b/artifacts/plan.json`
  - `jobs/tc/job_tc_ddd14b6d5358d62b/runs/ca79c5a0fc8048c1a554e470a6386088/artifacts/stata.do`
  - `jobs/tc/job_tc_ddd14b6d5358d62b/runs/ca79c5a0fc8048c1a554e470a6386088/artifacts/ss_summary_table.csv`

### 2026-01-09 Persistence: Restart API and resume job state
- Command:
  - Stop/start API process
  - `GET /v1/jobs/job_tc_ddd14b6d5358d62b` after restart
- Key output:
  - Job status remains `succeeded` and artifacts index is intact
- Evidence:
  - `jobs/tc/job_tc_ddd14b6d5358d62b/job.json`

### 2026-01-09 Edge case: Missing columns fails with structured error
- Command:
  - Redeem + upload CSV without required columns, patch outcome/treatment to missing vars
  - `POST /v1/jobs/{job_id}/confirm`
- Key output:
  - `400 CONTRACT_COLUMN_NOT_FOUND (missing=ln_sales,policy)`
- Evidence:
  - Job: `jobs/tc/job_tc_82bfdf1eead9cfaa/job.json`

### 2026-01-09 Local checks (venv)
- Command:
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `All checks passed!`
  - `160 passed, 5 skipped`
- Evidence:
  - N/A
