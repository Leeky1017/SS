## 1. Implementation
- [ ] 1.1 Update `openspec/specs/ss-frontend-desktop-pro/spec.md` with redeem entry flow + token rules
- [ ] 1.2 Update FE-C002 and FE-C003 task cards with auth and acceptance updates
- [ ] 1.3 Add run log `openspec/_ops/task_runs/ISSUE-224.md`

## 2. Validation
- [ ] 2.1 `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 `rulebook task validate issue-224-ss-frontend-desktop-pro-auth`
- [ ] 2.3 `scripts/agent_pr_preflight.sh`

## 3. Delivery
- [ ] 3.1 Open PR with body `Closes #224`
- [ ] 3.2 Enable auto-merge and watch checks (`gh pr checks --watch`)
- [ ] 3.3 Backfill PR link in `openspec/_ops/task_runs/ISSUE-224.md`
