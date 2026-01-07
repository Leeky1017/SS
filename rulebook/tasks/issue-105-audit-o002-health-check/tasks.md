# Tasks: issue-105-audit-o002-health-check

- [x] Add liveness endpoint (`/health/live`) with stable JSON schema
- [x] Add readiness endpoint (`/health/ready`) with dependency checks + `503` on unhealthy
- [x] Ensure failures are structured and logged (no silent swallow)
- [x] Add tests covering liveness vs readiness semantics
- [x] Document probe configuration (Kubernetes example) in task card
- [x] Record `ruff check .` and `pytest -q` in `openspec/_ops/task_runs/ISSUE-105.md`
