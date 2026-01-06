# Spec — SS delivery infrastructure

## Goal

将 SS 仓库标准化为 `$openspec-rulebook-github-delivery` 工作流：

- GitHub：Issue/Branch/PR/Checks/Auto-merge 为唯一交付入口
- OpenSpec：每个任务可追溯（spec + runs）
- Rulebook：每个任务可执行拆解（proposal + tasks）

## Requirements

1) Workflow hard gates
- 分支名必须为 `task/<N>-<slug>`
- PR body 必须包含 `Closes #N`
- 必须提交 `openspec/_ops/task_runs/ISSUE-N.md`
- 必须通过 checks：`ci` / `openspec-log-guard` / `merge-serial`

2) Repo structure
- 根目录存在 `AGENTS.md` 与 `CONTRIBUTING.md`
- 存在 `.rulebook` 与 `rulebook/tasks/`
- 存在 `openspec/`（含 `specs/` 与 `_ops/task_runs/`）

## Scenarios (verifiable)

- PR 创建后，`openspec-log-guard` 能阻止缺失 `Closes #N` 或缺失 run log 的 PR 合并。
- `ci` 与 `merge-serial` 能在 PR 上运行 `ruff check .` 与 `pytest -q` 并通过。

