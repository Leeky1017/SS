## 1. Implementation
- [x] Inventory `assets/stata_do_library/` templates + meta/index + key docs
- [x] Add optimization OpenSpec: `openspec/specs/ss-do-template-optimization/`
- [x] Write delivery run log: `openspec/_ops/task_runs/ISSUE-125.md`

## 2. Validation
- [x] `rulebook task validate issue-125-do-template-optimization`
- [x] `ruff check .`
- [x] `pytest -q`

## 3. Delivery
- [ ] Run `scripts/agent_pr_preflight.sh`
- [ ] Open PR with `Closes #125` and enable auto-merge
