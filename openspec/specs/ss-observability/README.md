# SS Observability — Index

本目录定义 SS 的可观测性基线（结构化日志 + 必带字段）。

## 日志格式（JSON line）

SS 结构化日志以 JSON line 输出（实现：`src/infra/logging_config.py`），核心字段：
- `ts` / `level` / `logger` / `event`
- `job_id`（如适用）/ `run_id`（执行期）/ `step`（按需）
- `trace_id` / `span_id`（启用 tracing 时）

业务上下文必须通过 `logger.<level>(..., extra={...})` 提供，避免把上下文拼进 `event` 字符串里。

## 事件码（建议）

- 事件码格式：`SS_<AREA>_<ACTION>`（示例：`SS_JOB_CREATE`、`SS_RUN_START`、`SS_RUN_FAIL`）
- 每条日志至少带：
  - `job_id`
  - `run_id`（执行期）
  - `step`（按需）
  - `trace_id` / `span_id`（启用分布式追踪时，用于与 traces 关联）

## 必须记录的事件（最小集合）

- API：每个请求的 access log；请求校验失败（400）必须有事件码日志（含 `request_id`/`path`）。
- 状态变更：Job `status` 变更（含 from/to）；幂等 no-op；非法迁移/锁冲突/版本冲突。
- LLM：调用开始/结束；失败与 failover 决策（含 `job_id` + `llm_call_id`/provider/model 等可用字段）。
- Stata：执行尝试开始/结束；失败原因（含 `job_id` + `run_id` + `attempt` + `error_code`）。

## 日志级别（约定）

- `INFO`：正常生命周期事件（start/done）、状态推进、幂等 no-op。
- `WARNING`：可恢复异常（重试、回退、冲突、数据异常被识别但可继续）。
- `ERROR`：不可恢复失败（导致 5xx/启动门禁失败/Job 终态失败）。

## 配置来源（硬约束）

- log_level MUST 来自 `src/config.py`
- 其他模块 MUST NOT 直接读环境变量拼装日志行为

## 分布式追踪（W3C Trace Context）

- Trace context MUST 使用 `traceparent` / `tracestate`（标准 W3C header）
- Trace context MUST 在 API → queue → worker 边界上传播
- Traces/Logs MUST NOT 包含敏感信息（job 内容、prompt、token 等）

### 配置（来自 `src/config.py`）

- `SS_TRACING_ENABLED`：是否启用 tracing（默认 `0`）
- `SS_TRACING_SERVICE_NAME`：`service.name` 前缀（默认 `ss`）
- `SS_TRACING_EXPORTER`：`otlp` / `console`（默认 `otlp`）
- `SS_TRACING_OTLP_ENDPOINT`：OTLP HTTP traces endpoint（默认 `http://localhost:4318/v1/traces`）
- `SS_TRACING_SAMPLE_RATIO`：采样率 `0.0~1.0`（默认 `1.0`）

## 审计事件（Audit logging）

审计事件使用结构化日志 `event=SS_AUDIT_EVENT`，用于回答 “谁在什么时候做了什么”：

- 资源关联：`job_id`（以及 `audit_resource_type` / `audit_resource_id`）
- 请求关联：`request_id`（API 会回传响应头 `X-SS-Request-Id`，也支持透传 `X-Request-Id` / `X-SS-Request-Id`）
- 行为与结果：`audit_action` / `audit_result`
- 参与者：`audit_actor_kind` / `audit_actor_id` / `audit_actor_ip` / `audit_actor_user_agent`
- 变更：`audit_changes`（例如 `from_status` → `to_status`）

## Task cards

- `openspec/specs/ss-observability/task_cards/round-00-arch-a__ARCH-T061.md`（Issue #26）
