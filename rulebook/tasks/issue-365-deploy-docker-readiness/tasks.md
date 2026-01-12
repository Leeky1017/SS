## 1. Implementation
- [ ] 1.1 Add `openspec/specs/ss-deployment-docker-readiness/spec.md` (requirements + scenarios + acceptance)
- [ ] 1.2 Add task cards under `openspec/specs/ss-deployment-docker-readiness/task_cards/` (DEPLOY-READY-R001/R002/R003/R010/R011/R012/R020/R030/R031/R090)

## 2. Testing
- [ ] 2.1 `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 `ruff check .`
- [ ] 2.3 `pytest -q`
- [ ] 2.4 `scripts/agent_pr_preflight.sh`

## 3. Documentation
- [ ] 3.1 Update run log `openspec/_ops/task_runs/ISSUE-365.md` (commands + outputs + PR link)
- [ ] 3.2 Open PR with body `Closes #365` and enable auto-merge
