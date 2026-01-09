## 1. OpenSpec + Task Cards
- [ ] 1.1 Add `openspec/specs/frontend-stata-proxy-extension/spec.md` (strict-valid)
- [ ] 1.2 Add task cards under `openspec/specs/frontend-stata-proxy-extension/task_cards/` (FE-B001..FE-B005)
- [ ] 1.3 Ensure frontend tasks are not scattered into other specs

## 2. Run Log (Required)
- [ ] 2.1 Add `openspec/_ops/task_runs/ISSUE-211.md` skeleton (Issue/Branch/PR/Plan/Runs)
- [ ] 2.2 Record validate/preflight/PR/merge evidence in the run log

## 3. Validations
- [ ] 3.1 `openspec validate --specs --strict --no-interactive`
- [ ] 3.2 `scripts/agent_pr_preflight.sh`

## 4. GitHub Delivery
- [ ] 4.1 Commit with message containing `(#211)`
- [ ] 4.2 Push branch `task/211-frontend-stata-proxy-extension` and open PR with body `Closes #211`
- [ ] 4.3 Enable auto-merge and wait required checks (`ci`/`openspec-log-guard`/`merge-serial`)

## 5. Post-merge Closeout
- [ ] 5.1 Controlplane sync: `scripts/agent_controlplane_sync.sh`
- [ ] 5.2 Worktree cleanup: `scripts/agent_worktree_cleanup.sh "211" "frontend-stata-proxy-extension"`
- [ ] 5.3 Archive Rulebook task `issue-211-frontend-stata-proxy-extension`

