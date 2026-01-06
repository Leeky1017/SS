# Contributing（OpenSpec + Rulebook + GitHub）

本仓库的协作与交付必须遵守 `$openspec-rulebook-github-delivery`。

## 标准流程

1) 创建/选择 Issue（得到 `N`）
- Issue 号 `N` 是任务唯一 ID。

2) 创建分支（必须）
- `task/<N>-<slug>`

3) Spec-first（必须）
- 新增/更新 `openspec/specs/**/spec.md`
- 新增/更新 Rulebook task：`rulebook/tasks/issue-<N>-<slug>/`
- 新增/更新 run log：`openspec/_ops/task_runs/ISSUE-N.md`

4) 提交（必须）
- 每个 commit message 必须包含 `(#N)`

5) 提 PR（必须）
- PR body 必须包含 `Closes #N`
- 通过 checks：`ci` / `openspec-log-guard` / `merge-serial`
- 启用 auto-merge

## 常用命令

- 创建 worktree：`scripts/agent_worktree_setup.sh <N> <slug>`
- 同步控制面：`scripts/agent_controlplane_sync.sh`

## Repo Settings（一次性配置）

在 GitHub 仓库设置中：
- 开启 auto-merge
- 为 `main` 分支设置保护规则，并将 required checks 设为：
  - `ci`
  - `openspec-log-guard`
  - `merge-serial`
