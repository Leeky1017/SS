# Spec (Delta): Backend quality alignment (P4)

## Scope

本变更只做后端代码质量与规范落地：

- 对齐错误处理（结构化错误响应、错误码一致性、无堆栈泄露）
- 对齐结构化日志（事件码 + 上下文字段、日志级别一致）
- 可选：小范围去重与类型标注修复（不引入新功能）

## Requirements

### Requirement: API failures return stable structured errors

SS MUST return a stable structured error payload (`error_code`, `message`) for all non-2xx API responses, and MUST NOT expose stack traces or internal exception types in responses.

任何 API 非 2xx 响应必须返回：

- `error_code`：稳定、机器可读、`UPPER_SNAKE_CASE` 且带领域前缀（如 `INPUT_*`/`JOB_*`/`LLM_*`/`STATA_*`）
- `message`：人类可读且安全（不得暴露堆栈、内部异常类型、文件路径等敏感内部细节）

新增/变更错误码必须同步 `ERROR_CODES.md`。

### Requirement: Validation errors are stable

SS MUST return HTTP `400` with `error_code="INPUT_VALIDATION_FAILED"` for request validation failures.

请求参数校验失败必须返回 HTTP `400`，并使用 `INPUT_VALIDATION_FAILED` 作为错误码。

### Requirement: Domain errors preserve error_code without leaking internals

Domain services MUST surface expected failures with a stable `error_code`. The API MUST map them to a structured error response with a safe `message` and MUST NOT leak internal exception details.

Domain 层抛出的可预期失败必须带稳定 `error_code`，API 层负责映射为结构化错误响应，但不得把内部异常信息透传给用户。

### Requirement: Key operations emit structured logs

SS MUST emit JSON-line structured logs with stable event codes (`SS_<AREA>_<ACTION>`) and context fields via `extra={...}` for key operations.

关键链路必须记录结构化日志（JSON line）并使用稳定事件码 `SS_<AREA>_<ACTION>`，上下文通过 `extra={...}` 提供：

- API：请求 access log；请求校验失败（400）必须记录事件码日志（含 `request_id`/`path`）
- 状态变更：job 状态 from/to；幂等 no-op；非法迁移/锁冲突/版本冲突
- LLM：调用开始/结束；失败与 failover 决策（含 `job_id` + provider/model 等可用字段）
- Stata：执行开始/结束；失败原因（含 `job_id` + `run_id` + `attempt` + `error_code`）

日志级别约定：生命周期事件用 `INFO`；可恢复异常用 `WARNING`；不可恢复失败用 `ERROR`。

## Scenarios

#### Scenario: Unhandled exceptions do not leak stack traces
- **GIVEN** API 内部发生未捕获异常
- **WHEN** API 内部抛出未捕获异常
- **THEN** 响应为结构化错误（含 `error_code`/`message`）且不包含堆栈信息

#### Scenario: Domain illegal transition returns structured error
- **GIVEN** job 当前状态不允许迁移到目标状态
- **WHEN** 发生非法状态迁移
- **THEN** 失败返回稳定 `error_code`，并记录事件码日志（含 `job_id`/from/to）

#### Scenario: Logs contain contextual fields
- **GIVEN** job 生命周期进入执行阶段
- **WHEN** job 进入运行与失败/成功终态
- **THEN** 日志包含 `event` + `job_id` + `run_id`（如适用）+ 必要上下文字段
