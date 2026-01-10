## 1. Implementation
- [x] 1.1 Add controlplane-dirty guard to PR preflight
- [x] 1.2 Make worktree setup run controlplane sync and enforce repo-root execution
- [x] 1.3 Improve sync error output with dirty file list + remediation hint

## 2. Testing
- [x] 2.1 `python -m py_compile scripts/agent_pr_preflight.py`
- [x] 2.2 Smoke: run `scripts/agent_pr_preflight.sh` with clean controlplane

## 3. Documentation
- [x] 3.1 Record evidence in `openspec/_ops/task_runs/ISSUE-305.md`
