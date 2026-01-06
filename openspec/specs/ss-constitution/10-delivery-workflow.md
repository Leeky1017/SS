# 10 — 协作与交付流程（OpenSpec × Rulebook × GitHub）

目标：把“人-模型-代码”协作约束成可执行的流程，让 SS 的每一次变更都 **可追溯、可复现、可审计**。

## 三层职责（谁负责什么）

- OpenSpec（`openspec/`）：**规则与需求增量（spec-first）**。权威约束在 `openspec/specs/`。
- Rulebook（`rulebook/`）：**任务执行清单**（可勾选、可验收）。每个 Issue 都有一个 task。
- GitHub（Issue/Branch/PR/Checks/Auto-merge）：**并发与交付唯一入口**。所有变更必须走 PR。

补充：`openspec/_ops/task_runs/ISSUE-N.md` 是 SS 的“运行证据账本”，PR 必带。

## 必备产物（每个 Issue 必须具备）

- GitHub Issue：`#N`（任务唯一 ID）
- Branch：`task/<N>-<slug>`
- Rulebook task：`rulebook/tasks/issue-<N>-<slug>/`
- Run log：`openspec/_ops/task_runs/ISSUE-N.md`
- Spec delta：更新/新增 `openspec/specs/**/spec.md`（严格校验通过）

## 标准流程（Issue → PR → Merge）

### 0) 选定 Issue（得到 N）

- 没有 Issue 就先建 Issue（写清：目标/范围/验收标准）。
- 任何需求变更：先改 Issue/Spec，再改代码（禁止“先写代码再补 spec”）。

### 1) 创建 worktree（并行隔离）

在控制面（仓库根目录）执行：

```bash
scripts/agent_controlplane_sync.sh
scripts/agent_worktree_setup.sh <N> <slug>
cd .worktrees/issue-<N>-<slug>
```

搜索时避免重复命中 worktree：

```bash
rg -g'!.worktrees/**' -n "<pattern>" .
```

### 2) 落盘 run log（强制）

创建：`openspec/_ops/task_runs/ISSUE-<N>.md`，并在每次关键运行后追加：
- 命令（可复制）
- 关键输出（短片段）
- 证据路径（文件/日志/截图等）

### 3) 创建 Rulebook task（强制）

- task-id：`issue-<N>-<slug>`
- 填写：
  - `proposal.md`：本次变更影响面（ADDED/MODIFIED/REMOVED）
  - `tasks.md`：可勾选的执行拆解（按验收标准拆）

### 4) 写/改 OpenSpec（强制）

- 规则来源：
  - 工程宪法：`openspec/specs/ss-constitution/spec.md`
  - 写作标准：`openspec/specs/openspec-writing-standard/spec.md`
- 最小要求：所有 active spec 必须通过

```bash
openspec validate --specs --strict --no-interactive
```

### 5) 实现（按 tasks.md 推进）

- 分层边界：`api -> domain -> ports <- infra`（业务不依赖 FastAPI）
- 依赖显式注入；配置只从 `src/config.py` 读取
- 禁止动态代理/隐式转发；禁止吞异常
- 尺寸上限：函数 `< 50` 行；文件 `< 300` 行（超限必须拆分）

提交要求（强制）：
- 每个 commit message 必须包含 `(#N)`

### 6) 本地验证（强制）

```bash
openspec validate --specs --strict --no-interactive
ruff check .
pytest -q
```

把关键输出写入 run log：`openspec/_ops/task_runs/ISSUE-N.md`。

### 7) PR + Auto-merge（强制）

- PR body 必须包含：`Closes #N`
- PR 必须包含：`openspec/_ops/task_runs/ISSUE-N.md`
- 通过 required checks：`ci` / `openspec-log-guard` / `merge-serial`
- 必须启用 auto-merge（推荐用仓库脚本一键做）

```bash
scripts/agent_pr_automerge_and_sync.sh
```

### 8) 合并后收口（强制）

- 控制面同步：`scripts/agent_controlplane_sync.sh`
- 归档 Rulebook task（保持任务树干净）

## OpenSpec changes/ 的使用策略（可选）

OpenSpec 官方模型是“两文件夹”：
- `openspec/specs/`：当前真实（source of truth）
- `openspec/changes/`：提案与增量（proposal + tasks + spec deltas），完成后 archive 回写 specs

在 SS 中，默认每个 Issue 使用 Rulebook tasks；仅当满足以下任一条件时才启用 `openspec/changes/`：
- 一个议题需要同时改多个 spec，且希望把 proposal/tasks/spec delta 收拢在一个 change folder
- 需要跨多个 Issue 的“阶段性设计提案”（先对齐再拆子 Issue）

启用时约定：
- `change-id` 建议使用：`issue-<N>-<slug>`
- change folder 结构遵循官方习惯：`openspec/changes/<change-id>/{proposal.md,tasks.md,specs/...}`
- 归档操作使用 OpenSpec CLI：`openspec archive <change-id> --yes`

