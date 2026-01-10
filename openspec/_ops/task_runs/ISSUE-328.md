# ISSUE-328
- Issue: #328 https://github.com/Leeky1017/SS/issues/328
- Branch: task/328-prod-e2e-r011-template-selection
- PR: https://github.com/Leeky1017/SS/pull/332

## Goal
- In `GET /v1/jobs/{job_id}/draft/preview`, select a real do-template via `DoTemplateSelectionService`, archive auditable selection evidence (stage1/candidates/stage2), and persist `selected_template_id` onto the job record (no hard-coded template ids).

## Status
- CURRENT: Implemented v1 draft preview template selection (evidence + persisted selected_template_id); ruff/pytest green; captured one real run evidence; preparing PR.

## Next Actions
- [x] Implement selection in `GET /v1/jobs/{job_id}/draft/preview`
- [x] Persist artifacts evidence (stage1/candidates/stage2)
- [x] Persist `selected_template_id` into job record
- [x] Remove `template_id="stub_descriptive_v1"` hardcode in `src/domain/plan_service.py` (already removed)
- [x] Run `ruff check .` and `pytest -q`
- [x] Record a real E2E run evidence (artifact paths) in this run log
- [ ] Run `scripts/agent_pr_preflight.sh`
- [ ] Open PR and enable auto-merge; verify PR is `MERGED`

## Decisions Made
- 2026-01-10: Keep plan freeze template selection unchanged for now; persist + evidence v1 selection on draft preview, and leave plan consumption to follow-up remediation tasks.

## Errors Encountered
- 2026-01-10: `scripts/agent_pr_preflight.sh` blocked by dirty controlplane (unrelated Issue #329 files) → restored + removed untracked archive; reran preflight OK.

## Runs
### 2026-01-10 Setup: issue + worktree
- Command:
  - `gh issue create -t "[ROUND-01-PROD-A] PROD-E2E-R011: 在 v1 旅程中执行模板选择（不再硬编码）" -b "<body omitted>"`
  - `scripts/agent_worktree_setup.sh "328" "prod-e2e-r011-template-selection"`
- Key output:
  - `https://github.com/Leeky1017/SS/issues/328`
  - `Worktree created: .worktrees/issue-328-prod-e2e-r011-template-selection`
  - `Branch: task/328-prod-e2e-r011-template-selection`
- Evidence:
  - (this file)

### 2026-01-10 Validation: ruff + pytest
- Command:
  - `/home/leeky/work/SS/.venv/bin/ruff check .`
  - `/home/leeky/work/SS/.venv/bin/pytest -q`
- Key output:
  - `All checks passed!`
  - `176 passed, 5 skipped`
- Evidence:
  - (this file)

### 2026-01-10 E2E: v1 draft preview triggers template selection
- Command:
  - ASGI client run (dependency overrides: file job store + traced fake LLM) writing evidence under `/tmp/ss_e2e_328/20260110T094501Z/`
- Key output:
  - `job_id=job_tc_eb24329f5ff81720`
  - `selected_template_id=TL01`
  - Selection artifacts:
    - `/tmp/ss_e2e_328/20260110T094501Z/jobs/tc/job_tc_eb24329f5ff81720/artifacts/do_template/selection/stage1.json`
    - `/tmp/ss_e2e_328/20260110T094501Z/jobs/tc/job_tc_eb24329f5ff81720/artifacts/do_template/selection/candidates.json`
    - `/tmp/ss_e2e_328/20260110T094501Z/jobs/tc/job_tc_eb24329f5ff81720/artifacts/do_template/selection/stage2.json`
  - LLM meta (auditable):
    - `/tmp/ss_e2e_328/20260110T094501Z/jobs/tc/job_tc_eb24329f5ff81720/artifacts/llm/do_template.select_template-20260110T094501452076Z-b9e7af26c47a/meta.json` (`model=fake`, `operation=do_template.select_template`)
- Evidence:
  - `/tmp/ss_e2e_328/20260110T094501Z/`

### 2026-01-10 Preflight: roadmap + open PR overlap
- Command:
  - `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
- Evidence:
  - (this file)

### 2026-01-10 PR: open
- Command:
  - `gh pr create --title \"[ROUND-01-PROD-A] PROD-E2E-R011: v1 draft preview selects template (#328)\" --body \"Closes #328 ...\"`
- Key output:
  - `https://github.com/Leeky1017/SS/pull/332`
- Evidence:
  - PR: https://github.com/Leeky1017/SS/pull/332
