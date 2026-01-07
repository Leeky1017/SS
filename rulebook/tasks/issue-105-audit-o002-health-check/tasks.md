# Tasks: issue-105-audit-o002-health-check

- [ ] Add liveness endpoint (`/health/live`) with stable JSON schema
- [ ] Add readiness endpoint (`/health/ready`) with dependency checks + `503` on unhealthy
- [ ] Ensure failures are structured and logged (no silent swallow)
- [ ] Add tests covering liveness vs readiness semantics
- [ ] Document probe configuration (Kubernetes example) in task card
- [ ] Record `ruff check .` and `pytest -q` in `openspec/_ops/task_runs/ISSUE-105.md`

