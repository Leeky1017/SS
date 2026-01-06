## 1. Implementation
- [ ] 1.1 Enforce artifact `rel_path` safety for read/write (reject `..`/absolute, prevent symlink escape)
- [ ] 1.2 Redact LLM artifacts and avoid logging sensitive raw values
- [ ] 1.3 Restrict runner execution to safe working dir + minimal do-file safety gate

## 2. Testing
- [ ] 2.1 Unit tests: artifact traversal + symlink escape rejected
- [ ] 2.2 Unit tests: runner rejects unsafe do-file content and unsafe workspace ids

## 3. Documentation
- [ ] 3.1 Add/confirm spec deltas in task folder (`specs/ss-security/spec.md`)
- [ ] 3.2 Update `openspec/_ops/task_runs/ISSUE-27.md` with commands + key outputs
