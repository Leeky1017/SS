## 1. Specification
- [x] 1.1 Update constitution to define infra adapters vs shared application infrastructure
- [x] 1.2 Update ports-and-services spec to permit domain -> shared application infrastructure

## 2. Validation
- [x] 2.1 Run `openspec validate --specs --strict --no-interactive`
- [x] 2.2 Run `ruff check .` and `pytest -q`

## 3. Delivery
- [ ] 3.1 Update `openspec/_ops/task_runs/ISSUE-409.md` with commands + key outputs
- [ ] 3.2 Open PR with `Closes #409` and enable auto-merge
