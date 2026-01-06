# Spec — Agent auto-merge + controlplane sync

## Goal

在 `$openspec-rulebook-github-delivery` 工作流下，实现“完全自动化”的收口动作：
- PR 通过 checks 后自动合并
- 合并完成后，本地 controlplane `main` 自动与 `origin/main` 同步

## Requirements

1) New script
- 存在 `scripts/agent_pr_automerge_and_sync.sh`
- 支持从任意 worktree 执行（不要求当前目录是 controlplane）
- 能解析当前分支 `task/<N>-<slug>` 并要求：
  - PR body 包含 `Closes #N`
  - `openspec/_ops/task_runs/ISSUE-N.md` 已存在于 HEAD
- 能完成：
  - 创建 PR（若不存在）
  - 启用 auto-merge（squash）
  - 等待 checks 全绿
  - 等待 PR merged
  - 同步 controlplane `main` 到 `origin/main`

2) Controlplane sync script
- `scripts/agent_controlplane_sync.sh` 必须能在 worktree 内运行（通过 `git --git-common-dir` 定位 controlplane）

3) Repo docs
- `CONTRIBUTING.md` 指导优先使用新脚本完成 PR + auto-merge + sync

## Scenarios (verifiable)

### Scenario: PR auto-merge and controlplane sync work end-to-end

Given a branch `task/<N>-<slug>` with a valid run log `openspec/_ops/task_runs/ISSUE-N.md`  
When running `scripts/agent_pr_automerge_and_sync.sh` from a worktree  
Then a PR is created (if missing), auto-merge is enabled, checks pass, PR is merged, and local controlplane `main` equals `origin/main`.

