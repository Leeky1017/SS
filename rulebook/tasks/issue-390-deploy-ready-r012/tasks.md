## 1. Implementation
- [x] 1.1 Update `ss-deployment-docker-readiness` with host-mounted Stata defaults and scenarios.
- [x] 1.2 Add runnable compose example for host-mounted Stata.
- [x] 1.3 Fail fast on missing/invalid `SS_STATA_CMD` at worker startup.
- [x] 1.4 Update task card metadata/checklist + run log evidence.

## 2. Testing
- [x] 2.1 Add/extend unit tests for worker Stata startup gating.
- [x] 2.2 Run `ruff check .` and `pytest -q`.

## 3. Documentation
- [x] 3.1 Ensure operator-facing compose/env example is actionable and references canonical env keys from `src/config.py`.
