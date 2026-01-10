## 1. Implementation
- [x] 1.1 Inventory current router mounts and legacy paths
- [x] 1.2 Remove unversioned business router mounting (keep ops endpoints only)
- [x] 1.3 Ensure job/draft/bundle/upload-session routes are only under `/v1`

## 2. Testing
- [x] 2.1 Add regression test: `/jobs/**` returns 404; `/v1/**` remains reachable
- [x] 2.2 Run `ruff check .` and `pytest -q`

## 3. Documentation
- [x] 3.1 Update run log `openspec/_ops/task_runs/ISSUE-297.md` with routing + curl evidence
