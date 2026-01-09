## 1. Implementation
- [ ] 1.1 Add spec directory `openspec/specs/ss-inputs-upload-sessions/` with `spec.md`
- [ ] 1.2 Add UPLOAD-C001–UPLOAD-C006 task cards under `openspec/specs/ss-inputs-upload-sessions/task_cards/`
- [ ] 1.3 Add run log `openspec/_ops/task_runs/ISSUE-227.md`

## 2. Validation
- [ ] 2.1 `openspec validate --specs --strict --no-interactive`
- [ ] 2.2 `rulebook task validate issue-227-ss-inputs-upload-sessions`
- [ ] 2.3 `scripts/agent_pr_preflight.sh` (best-effort if git fetch is unavailable)

## 3. Delivery
- [ ] 3.1 Open PR with body `Closes #227`
- [ ] 3.2 Enable auto-merge and watch checks (`gh pr checks --watch`)
- [ ] 3.3 Backfill PR link in `openspec/_ops/task_runs/ISSUE-227.md`
