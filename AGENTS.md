# SS — Agent Instructions

本仓库目标：构建一个以 **LLM 为“大脑”** 的 Stata 实证分析自动化系统（可维护性优先）。

## 代码原则（硬约束）

- YAGNI：不需要的不写；先把最小链路跑通再扩展。
- 尺寸上限：
  - 每个函数 `< 50` 行
  - 每个文件 `< 300` 行（超过必须拆分）
- 显式优于隐式：
  - 依赖必须显式注入（FastAPI `Depends` / 构造函数参数）
  - 配置从 `src/config.py` 加载，不要到处读环境变量
- 禁止动态代理/隐式转发：
  - 禁止 `__getattr__` 代理/ModuleAttrProxy
  - 禁止用“延迟 import 模块”绕循环依赖；要重组依赖或做依赖注入

## 异常与防御性编程（硬约束）

- 禁止 `except Exception: pass` 或 `except: pass`。
- 只捕获**具体异常类型**，并记录结构化日志（事件码 + 上下文）。
- 默认值必须显式：`data.get("key", "")`；不要用 `or ""` 破坏 `0/False/[]` 语义。

## 分层边界（保持链路最短）

- `src/api/`：HTTP 薄层（参数校验/响应组装），不要写业务。
- `src/domain/`：业务逻辑（纯业务 + 显式依赖），不要依赖 FastAPI。
- `src/infra/`：持久化/外部系统适配（job store、LLM provider、Stata runner 等）。
- `src/utils/`：极少量通用工具（避免工具泛滥）。

## 交付流程（必须遵守）

本仓库沿用 `$openspec-rulebook-github-delivery`：

- GitHub 是并发与交付唯一入口：**Issue → Branch → PR → Checks → Auto-merge**。
- Issue 号 `N` 是任务唯一 ID：
  - 分支名：`task/<N>-<slug>`
  - 每个 commit message 必须包含 `(#N)`
  - PR body 必须包含 `Closes #N`
  - 必须新增/更新：`openspec/_ops/task_runs/ISSUE-N.md`
- PR 需要通过 required checks：`ci` / `openspec-log-guard` / `merge-serial`。

## 本地验证

- `ruff check .`
- `pytest -q`

