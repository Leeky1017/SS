## 1. Execution (audit journey)
- [ ] 1.1 Start API + worker with real deps (real Stata + non-stub LLM; record runner/provider/model evidence)
- [ ] 1.2 Redeem task code (`POST /v1/task-codes/redeem`) and capture response fields
- [ ] 1.3 Upload CSV (`POST /v1/jobs/{job_id}/inputs/upload`) and capture response fields
- [ ] 1.4 Inputs preview + draft preview (`GET .../inputs/preview`, `GET .../draft/preview`)
- [ ] 1.5 Missing params structured error: attempt `POST .../plan/freeze` with missing required params and capture structured error
- [ ] 1.6 Provide corrections/answers and freeze plan successfully; download `plan.json` and verify contract fields
- [ ] 1.7 Run job + poll to terminal; download `stata.do`, `stata.log`, and at least one data artifact
- [ ] 1.8 Restart API/worker and show job + artifacts are recoverable

## 2. Judgement (go/no-go)
- [ ] 2.1 Template selection not hard-coded: evidence in plan + selection artifacts
- [ ] 2.2 Missing params structured error: PASS with error_code + missing identifiers
- [ ] 2.3 Dependency handling diagnosable + retryable: evidence in plan + failure/retry path
- [ ] 2.4 Artifact contract complete: plan contract + artifact index/downloads match
- [ ] 2.5 Verdict `READY` and blockers list empty in run log

## 3. Validation
- [ ] 3.1 `openspec validate --specs --strict --no-interactive`
- [ ] 3.2 `ruff check .`
- [ ] 3.3 `pytest -q`

## 4. Delivery
- [ ] 4.1 Update run log: `openspec/_ops/task_runs/ISSUE-352.md`
- [ ] 4.2 Run `scripts/agent_pr_preflight.sh`
- [ ] 4.3 Open PR and enable auto-merge; verify PR is `MERGED`
- [ ] 4.4 Sync controlplane `main` and cleanup worktree
