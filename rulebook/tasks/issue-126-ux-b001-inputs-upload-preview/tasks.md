## 1. Implementation
- [x] 1.1 Add job inputs domain service (upload + preview)
- [x] 1.2 Persist dataset under `inputs/` + write `inputs/manifest.json`
- [x] 1.3 Update `job.json` with `inputs.manifest_rel_path` + `inputs.fingerprint`
- [x] 1.4 Add API endpoints under `/v1` with explicit DI
- [x] 1.5 Add structured input error codes

## 2. Testing
- [x] 2.1 Upload CSV happy path + preview returns columns/rows
- [x] 2.2 Empty file returns `INPUT_EMPTY_FILE`
- [x] 2.3 Unsupported extension returns `INPUT_UNSUPPORTED_FORMAT`
- [x] 2.4 Malformed CSV returns `INPUT_PARSE_FAILED`
- [x] 2.5 Path traversal filename is rejected

## 3. Documentation
- [x] 3.1 Update run log `openspec/_ops/task_runs/ISSUE-126.md`
- [ ] 3.2 Update task card completion section (PR-linked)
