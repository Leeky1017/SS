## 1. Task Card Rewrite
- [ ] 1.1 Rewrite `backend__stata-proxy-extension.md` to be implementation-focused (not spec/delivery narration)
- [ ] 1.2 Ensure checklist aligns to `openspec/specs/backend-stata-proxy-extension/spec.md` and is testable
- [ ] 1.3 Confirm no changes to `index.html` and no `src/**/*.py` changes in this Issue

## 2. Run Log (Required)
- [ ] 2.1 Add `openspec/_ops/task_runs/ISSUE-209.md` skeleton (Issue/Branch/PR/Plan/Runs)
- [ ] 2.2 Record validate/preflight/PR evidence in the run log

## 3. Validations
- [ ] 3.1 `openspec validate --specs --strict --no-interactive`
- [ ] 3.2 `scripts/agent_pr_preflight.sh`

## 4. GitHub Delivery
- [ ] 4.1 Commit with message containing `(#209)`
- [ ] 4.2 Push branch `task/209-backend-proxy-taskcard` and open PR with body `Closes #209`
- [ ] 4.3 Enable auto-merge and wait required checks (`ci`/`openspec-log-guard`/`merge-serial`)
