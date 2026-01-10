# ISSUE-274
- Issue: #274 https://github.com/Leeky1017/SS/issues/274
- Branch: task/274-production-e2e-audit
- PR: <fill-after-created>

## Goal
- Perform a production-grade E2E audit of SS: confirm the real runtime chain, run the `/v1` journey end-to-end with a real Stata runner and a real (non-stub) LLM using `SS_LLM_MODEL=claude-opus-4-5-20251101`, and produce a go/no-go verdict with evidence.

## Status
- CURRENT: E2E run completed locally; recreating spec + run log inside the Issue worktree and preparing PR.

## Next Actions
- [ ] Run `openspec validate --specs --strict --no-interactive`.
- [ ] Run `ruff check .` and `pytest -q`.
- [ ] Run `scripts/agent_pr_preflight.sh`.
- [ ] Open PR (spec pack + run log only) and update `PR:`.
- [ ] Enable auto-merge and watch required checks; verify PR is `MERGED`.
- [ ] Sync controlplane `main` and cleanup worktree.

## Decisions Made
- 2026-01-10: Audit-only scope: do not modify `src/**` or `assets/stata_do_library/**`.
- 2026-01-10: For audit execution, override `.env` defaults to meet hard requirements:
  - `SS_LLM_PROVIDER=yunwu` (no stub)
  - `SS_LLM_MODEL=claude-opus-4-5-20251101`
  - `SS_STATA_CMD="...StataMP-64.exe"` (real Stata runner)

## Errors Encountered
- 2026-01-10: `scripts/agent_controlplane_sync.sh` failed once with `fatal: Cannot fast-forward to multiple branches.` → reran and it succeeded.

## Runs
### 2026-01-10 Setup: GitHub gates + worktree
- Command:
  - `gh auth status`
  - `git remote -v`
  - `gh issue create -t "[AUDIT] SS production E2E audit spec + run log" -b "<body omitted>"`
  - `git clean -fd` (remove untracked local logs/task dirs that block sync scripts)
  - `scripts/agent_controlplane_sync.sh` (first run failed; second run succeeded)
  - `scripts/agent_worktree_setup.sh "274" "production-e2e-audit"`
- Key output:
  - `Logged in to github.com account Leeky1017`
  - `origin https://github.com/Leeky1017/SS.git (fetch/push)`
  - `https://github.com/Leeky1017/SS/issues/274`
  - `fatal: Cannot fast-forward to multiple branches.`
  - `Already up to date.`
  - `Worktree created: .worktrees/issue-274-production-e2e-audit`
  - `Branch: task/274-production-e2e-audit`
- Evidence:
  - (this file)

### 2026-01-10 Inventory: routing surfaces and do-template wiring (wired vs present)
- Command:
  - `rg -n "api_v1_router|api_router|include_router\\(" src/api/routes.py src/main.py`
  - `sed -n "1,120p" src/api/routes.py`
  - `sed -n "1,160p" src/main.py`
  - `rg -n "LEGACY_UNVERSIONED_PREFIXES|Sunset|Deprecation" src/api/versioning.py`
  - `rg -n "SS_LLM_PROVIDER|SS_STATA_CMD|FakeStataRunner|LocalStataRunner" src/config.py src/worker.py`
  - `rg -n "stub_descriptive_v1|template_id" src/domain/plan_service.py src/domain/do_file_generator.py`
- Key output:
  - Routing surfaces:
    - `/v1/**` mounted via `api_v1_router = APIRouter(prefix=\"/v1\")` (`src/api/routes.py`)
    - legacy unversioned routers are also mounted (hidden from OpenAPI) via `app.include_router(api_router, include_in_schema=False)` (`src/main.py`)
    - legacy deprecation headers apply to unversioned `/jobs/**` via `LEGACY_UNVERSIONED_PREFIXES = (\"/jobs\",)` (`src/api/versioning.py`)
  - LLM + runner defaults:
    - `SS_LLM_PROVIDER` defaults to `stub` (`src/config.py`)
    - worker selects `FakeStataRunner` unless `SS_STATA_CMD` is set (`src/worker.py`)
  - Do-template chain classification:
    - Plan freeze hard-codes `template_id: \"stub_descriptive_v1\"` (`src/domain/plan_service.py`)
    - `DoFileGenerator` only supports `stub_descriptive_v1` and rejects others (`src/domain/do_file_generator.py`)
    - Do-template library ports/adapters exist (`src/domain/do_template_*`, `src/infra/fs_do_template_*`) but are not wired into `/v1` plan+run chain.
- Evidence:
  - `src/api/routes.py`
  - `src/main.py`
  - `src/api/versioning.py`
  - `src/config.py`
  - `src/worker.py`
  - `src/domain/plan_service.py`
  - `src/domain/do_file_generator.py`

### 2026-01-10 Inventory: `/v1` vs non-`/v1` endpoint list (connected surfaces)
- Command:
  - `rg -n \"@router\\.(get|post|put|delete|patch)\\(\" src/api/*.py`
  - `sed -n \"1,120p\" src/api/routes.py`
- Key output:
  - `/v1` mounted routers (`src/api/routes.py`):
    - `/v1/jobs/**` (jobs + draft endpoints via shared routers)
    - `/v1/task-codes/redeem` (task-codes router; no unversioned equivalent)
    - `/v1/jobs/{job_id}/inputs/bundle` (bundle router; v1-only)
    - `/v1/jobs/{job_id}/inputs/upload-sessions` + `/v1/upload-sessions/{upload_session_id}/...` (v1-only)
  - non-`/v1` mounted routers (hidden from OpenAPI via `include_in_schema=False`):
    - `/jobs/**` (jobs + draft endpoints; legacy, deprecated via headers)
    - `/health/live`, `/health/ready` (health router; unversioned only)
    - `/metrics` (metrics router; unversioned only)
- Evidence:
  - `src/api/routes.py`
  - `src/api/jobs.py`
  - `src/api/draft.py`
  - `src/api/task_codes.py`
  - `src/api/inputs_bundle.py`
  - `src/api/inputs_upload_sessions.py`
  - `src/api/health.py`
  - `src/api/metrics.py`

### 2026-01-10 E2E: `/v1` journey succeeds with real Stata + non-stub LLM (Opus 4.5)
- Command:
  - Start API + worker (load `/home/leeky/work/SS/.env` for `SS_LLM_API_KEY`, token redacted), overriding hard requirements:
    - `SS_LLM_PROVIDER=yunwu`
    - `SS_LLM_MODEL=claude-opus-4-5-20251101`
    - `SS_STATA_CMD="...StataMP-64.exe"` (quoted path)
    - `SS_JOBS_DIR=/tmp/ss_e2e_274/jobs`
    - `SS_QUEUE_DIR=/tmp/ss_e2e_274/queue`
  - Generate CSV:
    - `/tmp/ss_e2e_274/panel_274.csv`
  - Redeem:
    - `POST /v1/task-codes/redeem` (`task_code=tc_e2e_274_01`)
  - Upload + preview:
    - `POST /v1/jobs/{job_id}/inputs/upload` (CSV; `Authorization: Bearer <redacted>`)
    - `GET /v1/jobs/{job_id}/inputs/preview`
  - Draft preview:
    - `GET /v1/jobs/{job_id}/draft/preview`
  - Freeze + run:
    - `POST /v1/jobs/{job_id}/plan/freeze`
    - `POST /v1/jobs/{job_id}/run`
    - poll `GET /v1/jobs/{job_id}` until terminal
  - Artifacts:
    - `GET /v1/jobs/{job_id}/artifacts`
    - download `artifacts/plan.json`, `stata.do`, `stata.log`, `ss_summary_table.csv`
  - Restart API + worker, then:
    - `GET /v1/jobs/{job_id}`
    - `GET /v1/jobs/{job_id}/artifacts`
- Key output:
  - `job_id=job_tc_14f84baf3653a805` (token redacted; prefix `ssv1`)
  - HTTP status codes:
    - redeem: `200`
    - upload: `200`
    - inputs preview: `200`
    - draft preview: `200` (attempt 1)
    - plan freeze: `200`
    - run: `200`
    - final job status: `succeeded`
    - artifacts index: `200` (count: `12`)
    - after restart: `GET job=200`, `GET artifacts=200`
  - LLM evidence (non-stub + forced model):
    - `artifacts/llm/.../meta.json` includes `model=claude-opus-4-5-20251101`, `ok=true`
    - API log shows `SS_LLM_CALL_START` → `SS_LLM_CALL_DONE` (`ok=true`)
  - Stata evidence (real runner, not fake):
    - Worker log shows `SS_WORKER_RUNNER_SELECTED runner=local`
    - `SS_STATA_RUN_START cmd=[\".../StataMP-64.exe\",\"/e\",\"do\",\"stata.do\"]` → `exit_code=0`
  - Draft preview extracted vars (from `plan.json`):
    - `outcome_var=ln_sales`, `treatment_var=policy`, `controls=[ln_assets, leverage, roa]`
  - Plan freeze uses stub template (not do-template library):
    - `template_id=stub_descriptive_v1`
- Evidence:
  - HTTP request/response captures (local): `/tmp/ss_e2e_274/req/`
  - Downloads (local): `/tmp/ss_e2e_274/downloads/`
  - Job workspace (local):
    - `/tmp/ss_e2e_274/jobs/tc/job_tc_14f84baf3653a805/job.json`
    - `/tmp/ss_e2e_274/jobs/tc/job_tc_14f84baf3653a805/artifacts/plan.json`
    - `/tmp/ss_e2e_274/jobs/tc/job_tc_14f84baf3653a805/artifacts/llm/draft_preview-20260110T023338408555Z-356a247b554b/meta.json`
    - `/tmp/ss_e2e_274/jobs/tc/job_tc_14f84baf3653a805/runs/9296b26b2802469c838b9def86ce8163/artifacts/`
  - Logs (local):
    - `/tmp/ss_e2e_274/api.log`
    - `/tmp/ss_e2e_274/worker.log`
    - `/tmp/ss_e2e_274/api.restart.log`
    - `/tmp/ss_e2e_274/worker.restart.log`

### 2026-01-10 Validation: OpenSpec + ruff + pytest
- Command:
  - `openspec validate --specs --strict --no-interactive`
  - `ruff check .`
  - `pytest -q`
- Key output:
  - `Totals: 26 passed, 0 failed (26 items)`
  - `All checks passed!`
  - `162 passed, 5 skipped`
- Evidence:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - (this file)

### 2026-01-10 Preflight: roadmap + open PR overlap
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - (this file)

## Audit Conclusions (this Issue)

- Verdict: `NOT READY`

### Key audit points (pass/fail)
- Template selection (not hard-coded): **FAIL**
  - Evidence: `src/domain/plan_service.py` hard-codes `template_id="stub_descriptive_v1"`; `/tmp/ss_e2e_274/downloads/plan.json` shows `template_id=stub_descriptive_v1`.
- Parameter binding + structured error on missing inputs: **FAIL**
  - Evidence: `/tmp/ss_e2e_274/downloads/plan.json` has no explicit required-params contract; `src/domain/do_file_generator.py` supports only `stub_descriptive_v1` and does not enforce required analysis vars (missing vars do not yield a structured error).
- ado/SSC dependency handling (detect + recoverable retry): **FAIL**
  - Evidence: `/tmp/ss_e2e_274/downloads/plan.json` contains no dependency declaration; `/v1` run chain does not consume do-template meta dependencies.
- Artifact contract archiving + indexable downloadability: **PASS**
  - Evidence: `/tmp/ss_e2e_274/req/artifacts.json` lists `artifacts/plan.json` and run artifacts; downloads in `/tmp/ss_e2e_274/downloads/`; after restart `/tmp/ss_e2e_274/req/artifacts_after_restart.json` still returns `200` and artifacts remain downloadable.

### Blocking issues list

1) Do-template library is not wired into `/v1` plan/run (template selection is hard-coded)
   - Evidence:
     - `src/domain/plan_service.py` (`template_id="stub_descriptive_v1"`)
     - `src/domain/do_file_generator.py` (rejects any non-stub template)
     - `/tmp/ss_e2e_274/downloads/plan.json` (`template_id=stub_descriptive_v1`)
   - Impact:
     - Production “planning layer selects correct template” requirement cannot be met; do-template assets exist but are not executed in the `/v1` production journey.
   - Fix direction (not in this Issue):
     - Inject a template selection + repository dependency into plan generation; persist selection artifacts; remove stub-only template path from the `/v1` chain.

2) Plan freeze is missing explicit dependency info and output contract/index requirements
   - Evidence:
     - `/tmp/ss_e2e_274/downloads/plan.json` has no ado/SSC dependency declaration (no `dependencies` field or equivalent).
   - Impact:
     - Operators cannot preflight missing ado/SSC packages; missing dependency failures cannot be deterministically diagnosed and retried.
   - Fix direction (not in this Issue):
     - Extend the plan schema to include dependency declarations (from do-template meta); implement dependency check/install (or explicit failure) and a retry-safe pathway.

3) Parameter binding lacks a strict “missing params → structured error” path
   - Evidence:
     - `/tmp/ss_e2e_274/downloads/plan.json` does not encode required parameters; `analysis_spec` fields may be empty without triggering a structured binding error.
     - `src/domain/do_file_generator.py` generates a do-file even if `analysis_vars` is empty, so missing analysis fields are not rejected.
   - Impact:
     - Silent wrong runs: users can run with incomplete bindings without a clear error; violates the “missing params produce structured error” audit gate.
   - Fix direction (not in this Issue):
     - Use do-template meta param specs as a binding contract; enforce missing/invalid parameters with structured errors at plan freeze time (or before queue).

4) Production safety: stub LLM and fake runner are allowed without an explicit “production mode” gate
   - Evidence:
     - `src/config.py`: `SS_LLM_PROVIDER` default is `stub`
     - `src/worker.py`: selects `FakeStataRunner` unless `SS_STATA_CMD` is set
     - `src/domain/health_service.py`: readiness reports `llm` as `ok=true` regardless of provider (it only reports class name)
     - Local audit required overriding `.env` defaults to meet “no stub + real Stata” requirements (see E2E Runs).
   - Impact:
     - High risk of deploying a “healthy” service that silently uses stub LLM and/or fake Stata runner; production behavior deviates from required capabilities.
   - Fix direction (not in this Issue):
     - Add an explicit production mode config gate (disallow stub LLM + fake runner) and make `/health/ready` fail when violated; document required env vars for production.
