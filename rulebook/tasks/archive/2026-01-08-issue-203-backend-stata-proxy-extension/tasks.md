# Tasks: issue-203-backend-stata-proxy-extension

## 1. Spec-first deliverables
- [ ] Write OpenSpec: `openspec/specs/backend-stata-proxy-extension/spec.md`
- [ ] Add OpenSpec task card: `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`
- [ ] Create run log: `openspec/_ops/task_runs/ISSUE-203.md` (record key commands + outputs)

## 2. Local validation (spec-only)
- [ ] `openspec validate --specs --strict --no-interactive`
- [ ] `ruff check .`
- [ ] `pytest -q`

## 3. Delivery gates (GitHub)
- [ ] Run `scripts/agent_pr_preflight.sh` and record output in the run log
- [ ] Commit with message containing `(#203)`
- [ ] Open PR with body containing `Closes #203`
- [ ] Enable auto-merge and wait for required checks: `ci` / `openspec-log-guard` / `merge-serial`
