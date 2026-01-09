## 1. Implementation
- [ ] 1.1 Create spec directory `openspec/specs/ss-frontend-desktop-pro/` with `spec.md`
- [ ] 1.2 Add FE-C001–FE-C006 task cards under `openspec/specs/ss-frontend-desktop-pro/task_cards/`
- [ ] 1.3 Add run log `openspec/_ops/task_runs/ISSUE-222.md`

## 2. Validation
- [ ] 2.1 `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 `rulebook task validate issue-222-ss-frontend-desktop-pro`
- [ ] 2.3 `scripts/agent_pr_preflight.sh`

## 3. Delivery
- [ ] 3.1 Open PR with body `Closes #222`
- [ ] 3.2 Enable auto-merge and watch checks (`gh pr checks --watch`)
- [ ] 3.3 Backfill PR link in `openspec/_ops/task_runs/ISSUE-222.md`
