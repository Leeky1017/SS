## 1. Spec + Task Card Relocation
- [ ] 1.1 Move backend proxy spec to `openspec/specs/backend-stata-proxy-extension/spec.md`
- [ ] 1.2 Move task card to `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`
- [ ] 1.3 Update all references to the old paths (ripgrep in repo)

## 2. Run Log (Required)
- [ ] 2.1 Add `openspec/_ops/task_runs/ISSUE-207.md` skeleton (Issue/Branch/PR/Plan/Runs)
- [ ] 2.2 Record evidence for validate/preflight/PR in `openspec/_ops/task_runs/ISSUE-207.md`

## 3. Validations (Record in run log)
- [ ] 3.1 `openspec validate --specs --strict --no-interactive`
- [ ] 3.2 `scripts/agent_pr_preflight.sh`

## 4. GitHub Delivery
- [ ] 4.1 Commit changes with message containing `(#207)`
- [ ] 4.2 Push branch `task/207-backend-proxy-specs` and open PR with body `Closes #207`
- [ ] 4.3 Enable auto-merge and ensure required checks are green (`ci`/`openspec-log-guard`/`merge-serial`)
