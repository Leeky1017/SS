# SS Observability — Index

本目录定义 SS 的可观测性基线（结构化日志 + 必带字段）。

## 事件码（建议）

- 事件码格式：`SS_<AREA>_<ACTION>`（示例：`SS_JOB_CREATE`、`SS_RUN_START`、`SS_RUN_FAIL`）
- 每条日志至少带：
  - `job_id`
  - `run_id`（执行期）
  - `step`（按需）
  - `trace_id` / `span_id`（启用分布式追踪时，用于与 traces 关联）

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

## Task cards

- `openspec/specs/ss-observability/task_cards/round-00-arch-a__ARCH-T061.md`（Issue #26）
