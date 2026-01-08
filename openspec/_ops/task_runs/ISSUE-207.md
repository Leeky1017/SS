# ISSUE-207
- Issue: #207
- Branch: task/207-backend-proxy-specs
- PR: https://github.com/Leeky1017/SS/pull/208

## Plan
- Relocate backend proxy spec/task card into `openspec/specs/`
- Update internal references to canonical paths
- Validate (`openspec validate`) and ship via PR + auto-merge

## Runs
### 2026-01-08 Setup: worktree already created
- Command: `scripts/agent_worktree_setup.sh "207" "backend-proxy-specs"`
- Key output: `Worktree: .worktrees/issue-207-backend-proxy-specs`

### 2026-01-08 Relocation: spec + task card to canonical layout
- Command:
  - `git mv openspec/backend-stata-proxy-extension/spec.md openspec/specs/backend-stata-proxy-extension/spec.md`
  - `git mv openspec/specs/ss-job-contract/task_cards/backend__stata-proxy-extension.md openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`
- Evidence:
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
  - `openspec/specs/backend-stata-proxy-extension/task_cards/backend__stata-proxy-extension.md`

### 2026-01-08 Validate: OpenSpec
- Command:
  - `openspec validate backend-stata-proxy-extension --type spec --strict --no-interactive`
  - `openspec validate --specs --strict --no-interactive`
- Key output:
  - `Specification 'backend-stata-proxy-extension' is valid`
  - `Totals: 21 passed, 0 failed (21 items)`

### 2026-01-08 Preflight: overlap + roadmap deps
- Command: `scripts/agent_pr_preflight.sh`
- Key output:
  - `OK: no overlapping files with open PRs`
  - `OK: no hard dependencies found in execution plan`
