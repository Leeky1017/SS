# 01 — 原则与边界（Principles & Boundaries）

## 1) 系统目标

- 面向实证分析：输入数据与用户需求 → 生成可执行 Stata 流水线 → 产出可复现结果（表/图/log）。
- LLM 是“大脑”：负责计划与文本产物生成，但必须被结构化契约约束并可追溯。
- 可维护性优先：模块小、边界清晰、依赖显式、易测、可演进。

## 2) 非目标（明确不做）

- 不做“一次性全功能平台”：先把最小闭环跑通，再扩展分析能力。
- 不做把业务塞进 FastAPI：API 只做薄层，不承担状态机与 IO。
- 不做“隐式魔法”：禁止动态代理、隐式转发、运行时绕循环导入。

## 3) 分层边界（方向必须单向）

- `src/api/`：HTTP 薄层
  - 只做参数校验/响应组装
  - 依赖通过 `Depends` 注入（`src/api/deps.py`）
- `src/domain/`：业务逻辑
  - 只依赖 domain models + ports（接口）
  - 不依赖 FastAPI、文件系统、subprocess
- `src/infra/`：外部系统适配
  - JobStore（落盘）、LLM provider、StataRunner、Queue 等
  - 将外部复杂性隔离在边界内（异常统一映射）
- `src/utils/`：极少量通用工具
  - 仅放与领域无关的微工具（例如时间）

依赖方向：`api -> domain -> (ports) <- infra`。

## 4) 依赖注入（显式优于隐式）

- API：用 FastAPI `Depends` 构建 service（缓存可用 `lru_cache`，但要小心状态）。
- Domain：service 的依赖在构造函数显式传入（例如 `JobService(store, scheduler)`）。
- Infra：实现 ports，并在 deps 或 worker 启动时注入。

禁止：
- 通过全局单例 import re-export 共享状态
- 通过 `__getattr__` / 动态代理转发依赖
- 到处读环境变量（配置必须从 `src/config.py` 统一加载）

## 5) 异常与日志（必须可观测）

- 只捕获具体异常类型；严禁 `except Exception: pass` / `except: pass`。
- 错误必须结构化：`error_code` + `message` + `status_code`（参考 `src/infra/exceptions.py`）。
- 日志必须结构化：事件码（例如 `SS_JOB_CREATED`）+ `extra` 上下文（至少 `job_id`，执行期加 `run_id`/`step`）。

## 6) 文件与函数尺寸（硬门禁）

- 每个函数 `< 50` 行：职责拆小，便于测试与复用。
- 每个文件 `< 300` 行：超过必须拆分（尤其是 routes/pipeline 类文件）。

## 7) 交付节奏（最小闭环优先）

建议按以下“纵切”节奏推进（每一步都可验收、可回滚）：

1) job.json v1 + 状态机 + 查询 API
2) LLMPlan 冻结 + LLM artifacts
3) Worker + Queue（先 stub runner）
4) LocalStataRunner + DoFileGenerator（最小子集）
5) 丰富分析能力与 UI/交互（仍保持边界）

