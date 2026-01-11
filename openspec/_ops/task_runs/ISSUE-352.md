# ISSUE-352
- Issue: #352 https://github.com/Leeky1017/SS/issues/352
- Branch: task/352-prod-e2e-r090
- PR: <fill-after-created>

## Goal
- After all P0 remediation merges, re-run the full `ss-production-e2e-audit` journey and produce a `READY` go/no-go verdict with auditable evidence.

## Status
- CURRENT: Production E2E audit journey succeeded locally (attempt4) with evidence captured; preparing checks + PR.

## Next Actions
- [ ] Run `openspec validate --specs --strict --no-interactive`.
- [ ] Run `ruff check .` and `pytest -q`.
- [ ] Run `scripts/agent_pr_preflight.sh`.
- [ ] Open PR and update `PR:`; enable auto-merge and verify `MERGED`.
- [ ] Sync controlplane `main` and cleanup worktree.

## Decisions Made
- 2026-01-11: Audit-only change: ship run log + task card updates; no `src/**` or `assets/**` changes unless audit uncovers a regression.
- 2026-01-11: Unblocked `/v1/jobs/{job_id}/run` after a successful plan freeze by making plan-freeze confirmation fields idempotent (preserve existing notes/answers/etc when not re-supplied).
- 2026-01-11: Treat `SS_STATA_CMD` as a single path when it points to an existing file (supports WSL paths with spaces).

## Errors Encountered
- 2026-01-11: `POST /v1/jobs/{job_id}/run` returned `409 PLAN_ALREADY_FROZEN_CONFLICT` after a successful plan freeze → fixed via `PlanService._effective_confirmation` preserving existing confirmation fields (see Runs: Attempt1/2 + fix).
- 2026-01-11: Worker run failed with `STATA_SUBPROCESS_FAILED` (`No such file or directory: '/mnt/c/Program'`) due to `SS_STATA_CMD` being split on spaces → fixed via `load_config()` parsing (see Runs: Attempt3 + fix).

## Runs
### 2026-01-11 Setup: Issue/worktree + run log skeleton
- Command:
  - `gh auth status`
  - `git remote -v`
  - `gh issue create ...`
  - `scripts/agent_controlplane_sync.sh`
  - `scripts/agent_worktree_setup.sh "352" "prod-e2e-r090"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/352`
  - `Worktree created: .worktrees/issue-352-prod-e2e-r090`
  - `Branch: task/352-prod-e2e-r090`
- Evidence:
  - (this file)

### 2026-01-11 Attempt1/2: `/run` conflicts with frozen plan (pre-fix)
- Command:
  - Start API + worker (env via `/home/leeky/work/SS/.env`, key redacted):
    - `SS_LLM_PROVIDER=yunwu`
    - `SS_LLM_MODEL=claude-opus-4-5-20251101`
    - `SS_JOBS_DIR=/tmp/ss_e2e_352/jobs`, `SS_QUEUE_DIR=/tmp/ss_e2e_352/queue`
  - Execute the journey up to plan freeze, then call:
    - `POST /v1/jobs/{job_id}/run`
- Key output:
  - `POST /v1/jobs/job_tc_4b0343756eb65645/run` → `409` (`PLAN_ALREADY_FROZEN_CONFLICT`)
- Evidence:
  - Attempt1: `/tmp/ss_e2e_352/attempt1/req/10_run_trigger.response.json`
  - Attempt2: `/tmp/ss_e2e_352/attempt2/req/10_run_trigger.response.json`

### 2026-01-11 Fix: make `/run` idempotent with frozen confirmation
- Change:
  - Preserve existing confirmation fields (notes/answers/corrections/overrides/feedback) when callers do not re-supply them.
- Code:
  - `src/domain/plan_service.py`
- Evidence:
  - Subsequent `/run` no longer conflicts (see Attempt3+).

### 2026-01-11 Attempt3: runner fails due to `SS_STATA_CMD` path splitting (pre-fix)
- Command:
  - `SS_STATA_CMD=/mnt/c/Program Files/Stata18/StataMP-64.exe` (WSL path with spaces)
  - `POST /v1/jobs/{job_id}/run` and poll until terminal
- Key output:
  - Job reached `failed`
  - `run.error.json` → `error_code=STATA_SUBPROCESS_FAILED`, `message="[Errno 2] No such file or directory: '/mnt/c/Program'"`
- Evidence:
  - `/tmp/ss_e2e_352/attempt3/downloads/run_error_065a82159ccf4adb9e940b9610847dbd.json`
  - `/tmp/ss_e2e_352/attempt3/downloads/run.stderr_065a82159ccf4adb9e940b9610847dbd.txt`

### 2026-01-11 Fix: parse `SS_STATA_CMD` as a single path when it exists
- Change:
  - In `load_config()`, if `Path(SS_STATA_CMD).exists()` then treat it as a single command token (instead of `shlex.split`).
- Code:
  - `src/config.py`
- Test:
  - `tests/test_config_stata_cmd_parsing.py`

### 2026-01-11 Attempt4: full production E2E journey + restart recovery (PASS)
- Command:
  - Start API:
    - `SS_LLM_PROVIDER=yunwu`
    - `SS_LLM_MODEL=claude-opus-4-5-20251101`
    - `SS_JOBS_DIR=/tmp/ss_e2e_352/jobs`
    - `SS_QUEUE_DIR=/tmp/ss_e2e_352/queue`
    - `/home/leeky/work/SS/.venv/bin/python -m src.main`
  - Start worker:
    - `SS_STATA_CMD=/mnt/c/Program Files/Stata18/StataMP-64.exe` (parsed as a single cmd token)
    - `/home/leeky/work/SS/.venv/bin/python -m src.worker`
  - CSV input:
    - `/tmp/ss_e2e_352/panel_352.csv`
  - HTTP journey (responses saved; bearer token redacted):
    - `GET /health/live` → `200` (`/tmp/ss_e2e_352/req/00_health_live.response.json`)
    - `POST /v1/task-codes/redeem` → `200` (`job_id=job_tc_4b0343756eb65645`) (`/tmp/ss_e2e_352/req/01_redeem.response.json`)
    - `POST /v1/jobs/{job_id}/inputs/upload` → `200` (`fingerprint=sha256:...`) (`/tmp/ss_e2e_352/req/02_inputs_upload.response.json`)
    - `GET /v1/jobs/{job_id}/inputs/preview` → `200` (`row_count=120`) (`/tmp/ss_e2e_352/req/03_inputs_preview.response.json`)
    - `GET /v1/jobs/{job_id}/draft/preview` → `200` (`selected_template_id=T01`) (`/tmp/ss_e2e_352/req/04_draft_preview_attempt_1.response.json`, `/tmp/ss_e2e_352/req/04b_job_after_draft_preview.response.json`)
    - `POST /v1/jobs/{job_id}/plan/freeze` (missing) → `400 PLAN_FREEZE_MISSING_REQUIRED` (`missing_fields=["stage1_questions.analysis_goal"]`) (`/tmp/ss_e2e_352/req/05_plan_freeze_missing.response.json`)
    - `POST /v1/jobs/{job_id}/draft/patch` → `200` (`outcome_var=ln_sales`, `treatment_var=policy`) (`/tmp/ss_e2e_352/req/06_draft_patch.response.json`)
    - `POST /v1/jobs/{job_id}/plan/freeze` (success) → `200` (`plan_id=f862...`) (`/tmp/ss_e2e_352/req/07_plan_freeze_success.response.json`)
    - `POST /v1/jobs/{job_id}/run` → `200` then poll `GET /v1/jobs/{job_id}` → `status=succeeded` (`run_id=85b3042753424ab19af13cecac9e18e3`) (`/tmp/ss_e2e_352/req/10_run_trigger.response.json`, `/tmp/ss_e2e_352/req/11_job_poll_017.response.json`)
    - `GET /v1/jobs/{job_id}/artifacts` → `200` (`total=27`) (`/tmp/ss_e2e_352/req/12_artifacts_after_run.response.json`)
  - Downloads (local):
    - plan: `/tmp/ss_e2e_352/downloads/plan.json`
    - template selection: `/tmp/ss_e2e_352/downloads/do_template_selection_stage2.json`
    - llm meta: `/tmp/ss_e2e_352/downloads/llm_meta.json`
    - runner outputs: `/tmp/ss_e2e_352/downloads/stata.do`, `/tmp/ss_e2e_352/downloads/stata.log`
    - data artifact: `/tmp/ss_e2e_352/downloads/output_table.csv`
  - Restart recovery:
    - restart logs: `/tmp/ss_e2e_352/api.restart.log`, `/tmp/ss_e2e_352/worker.restart.log`
    - redeem again (idempotent): `/tmp/ss_e2e_352/req/20_redeem_after_restart.response.json`
    - `GET /v1/jobs/{job_id}` after restart: `/tmp/ss_e2e_352/req/21_job_after_restart.response.json`
    - `GET /v1/jobs/{job_id}/artifacts` after restart: `/tmp/ss_e2e_352/req/22_artifacts_after_restart.response.json`
- Key output:
  - LLM evidence: `/tmp/ss_e2e_352/downloads/llm_meta.json` → `model=claude-opus-4-5-20251101`, `ok=true`
  - Template selection evidence: `/tmp/ss_e2e_352/downloads/do_template_selection_stage2.json` → `selected_template_id=T01` with reason + confidence
  - Runner evidence (worker log):
    - `SS_WORKER_RUNNER_SELECTED` (`stata_cmd=["/mnt/c/Program Files/Stata18/StataMP-64.exe"]`)
    - `SS_STATA_RUN_START` → `SS_STATA_RUN_DONE exit_code=0`
  - Final job status: `succeeded`
- Evidence:
  - HTTP captures: `/tmp/ss_e2e_352/req/`
  - Downloads: `/tmp/ss_e2e_352/downloads/`
  - Job workspace: `/tmp/ss_e2e_352/jobs/tc/job_tc_4b0343756eb65645/`
  - Logs: `/tmp/ss_e2e_352/api.log`, `/tmp/ss_e2e_352/worker.log`

### 2026-01-11 Validation: OpenSpec + ruff + pytest
- Command:
  - `openspec validate --specs --strict --no-interactive`
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `Totals: 28 passed, 0 failed (28 items)`
  - `All checks passed!`
  - `184 passed, 5 skipped`
- Evidence:
  - (this file)

### 2026-01-11 Preflight: roadmap + open PR overlap
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - (this file)

## Audit Conclusions (this Issue)
- Verdict: `READY`

### Key audit points (pass/fail)
- Template selection (not hard-coded): **PASS**
  - Evidence: `/tmp/ss_e2e_352/downloads/do_template_selection_stage2.json` (`selected_template_id=T01`, reason + confidence); `/tmp/ss_e2e_352/downloads/plan.json` (`template_id=T01`).
- Missing params yield structured errors: **PASS**
  - Evidence: `/tmp/ss_e2e_352/req/05_plan_freeze_missing.response.json` (`error_code=PLAN_FREEZE_MISSING_REQUIRED`, `missing_fields=["stage1_questions.analysis_goal"]`, actionable `next_actions`).
- Dependency handling (diagnosable + retryable): **PASS**
  - Evidence: `/tmp/ss_e2e_352/downloads/plan.json` includes `template_contract.dependencies` (source+pkg); worker has explicit dependency preflight wiring before Stata execution (`src/domain/worker_plan_executor.py`).
- Artifact contract (complete + indexable downloads): **PASS**
  - Evidence: `/tmp/ss_e2e_352/downloads/plan.json` includes `outputs_contract` and `params_contract`; artifacts are indexable + downloadable pre/post restart (`/tmp/ss_e2e_352/req/12_artifacts_after_run.response.json`, `/tmp/ss_e2e_352/req/22_artifacts_after_restart.response.json`).

### Blockers list
- (empty)
