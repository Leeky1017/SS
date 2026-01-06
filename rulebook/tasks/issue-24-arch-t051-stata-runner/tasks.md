## 1. Spec-first
- [ ] 1.1 Confirm `openspec/specs/ss-stata-runner/spec.md` requirements are implemented by this change
- [ ] 1.2 Confirm workspace + artifact rules from `openspec/specs/ss-job-contract/README.md` are enforced

## 2. Implementation
- [ ] 2.1 Add domain `StataRunner` port + `RunResult`
- [ ] 2.2 Add infra `LocalStataRunner` (subprocess) enforcing run attempt working directory boundaries
- [ ] 2.3 Write artifacts: do-file, stdout/stderr, and structured error meta on failures

## 3. Testing
- [ ] 3.1 Add unit tests using a fake subprocess runner (no real Stata dependency)
- [ ] 3.2 (Optional) Add local integration test gated by env (real Stata installed)
- [ ] 3.3 Run `ruff check .` and `pytest -q` and record outputs in `openspec/_ops/task_runs/ISSUE-24.md`

## 4. Delivery
- [ ] 4.1 Add `openspec/_ops/task_runs/ISSUE-24.md`
- [ ] 4.2 Open PR with `Closes #24` and enable auto-merge
