# ISSUE-517
- Issue: #517
- Branch: task/517-spec-quality
- PR: https://github.com/Leeky1017/SS/pull/518

## Plan
- Fix task card 技术分析复制错误
- 补全 Dependencies 与 Priority
- 重写 task_cards/README.md 索引

## Runs
### 2026-01-18 init
- Command: `scripts/agent_worktree_setup.sh "517" "spec-quality"`
- Key output: `Worktree created: .worktrees/issue-517-spec-quality`
- Evidence: `openspec/_ops/task_runs/ISSUE-517.md`

### 2026-01-18 issue
- Command: `gh issue create -t "[SS-UX-REMEDIATION] FIX-SPEC-QUALITY-2026-01-18: task card tech analysis/deps/priorities" -b "<body>"`
- Key output: `https://github.com/Leeky1017/SS/issues/517`
- Evidence: `openspec/_ops/task_runs/ISSUE-517.md`

### 2026-01-18 commit
- Command: `git commit -m "docs: fix ss-ux-remediation task cards (#517)"`
- Key output: `21 files changed`
- Evidence: `openspec/specs/ss-ux-remediation/task_cards/`

### 2026-01-18 preflight
- Command: `scripts/agent_pr_preflight.sh`
- Key output: `OK: no overlapping files with open PRs`
- Evidence: `openspec/_ops/task_runs/ISSUE-517.md`

### 2026-01-18 tests
- Command: `python3 -m ruff check .`
- Key output: `No module named ruff`
- Evidence: `pyproject.toml`
- Command: `pytest -q`
- Key output: `ModuleNotFoundError: No module named 'pydantic'`
- Evidence: `requirements.txt`

### 2026-01-18 pr
- Command: `gh pr create --title "docs: fix ss-ux-remediation task cards (#517)" --body "Closes #517 ..."`
- Key output: `https://github.com/Leeky1017/SS/pull/518`
- Evidence: `openspec/_ops/task_runs/ISSUE-517.md`
