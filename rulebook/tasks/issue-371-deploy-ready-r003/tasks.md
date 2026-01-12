## 1. Implementation
- [x] 1.1 Inventory Docker/compose assets and entrypoints (API/worker/Stata).
- [x] 1.2 Compare against `ss-deployment-docker-readiness` and write numbered gap list + task mapping.
- [x] 1.3 Define minimal compose topology (MinIO + ss-api + ss-worker) and key volumes.
- [x] 1.4 Document Stata provisioning decision points/risks and recommended default path.

## 2. Testing
- [x] 2.1 Run `ruff check .`.
- [x] 2.2 Run `pytest -q`.

## 3. Documentation
- [x] 3.1 Update task card metadata/checklist: `openspec/specs/ss-deployment-docker-readiness/task_cards/audit__DEPLOY-READY-R003.md`.
- [x] 3.2 Add run log evidence: `openspec/_ops/task_runs/ISSUE-371.md`.
