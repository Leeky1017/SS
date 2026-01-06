# 01 — 原则与边界（Principles & Boundaries）

## 目标

- 以“可维护性优先”构建 SS：模块小、边界清晰、依赖显式、可测试、可演进。
- 把 LLM 的作用收敛为可审计、可回放、可替换的“主脑能力”，而不是黑箱魔法。

## 非目标（本阶段不做）

- 不做一次性全功能平台；先把最小闭环跑通。
- 不在 API 进程里跑 Stata；执行必须在 worker 中。
- 不用隐式全局/动态代理绕循环依赖；发现循环依赖就重组模块或做依赖注入。

## 分层边界（硬约束）

- `src/api/`（HTTP 薄层）
  - MUST 只做：参数校验/响应组装/依赖注入
  - MUST NOT：文件 IO、业务状态机、LLM 调用细节、subprocess 执行
- `src/domain/`（业务逻辑）
  - MUST：只依赖 domain models + ports（接口）
  - MUST NOT：依赖 FastAPI、文件系统、subprocess、第三方 SDK
- `src/infra/`（外部系统适配）
  - MUST：实现 ports（JobStore、LLM provider、Queue、StataRunner 等）
  - MUST：把外部复杂性隔离在边界内（异常映射、重试、超时）
- `src/utils/`（极少量工具）
  - SHOULD：只保留与领域无关的微工具

## 依赖注入（硬约束）

- API MUST 通过 `Depends` 注入 services（依赖集中在 `src/api/deps.py`）。
- Domain services MUST 通过构造函数显式注入依赖（store/llm/runner/queue）。
- Config MUST 统一由 `src/config.py` 加载；其他地方 MUST NOT 直接读环境变量。

## 异常与日志（硬约束）

- MUST 只捕获具体异常；MUST NOT `except Exception: pass` / `except: pass`。
- MUST 返回结构化错误：`error_code` + `message` + `status_code`（对齐 `SSError`）。
- MUST 记录结构化日志事件码（`SS_...`）+ 关键上下文（至少 `job_id`，执行期加 `run_id`/`step`）。

## 尺寸与可维护性（硬约束）

- 每个函数 MUST `< 50` 行；每个文件 MUST `< 300` 行（超过必须拆分）。

