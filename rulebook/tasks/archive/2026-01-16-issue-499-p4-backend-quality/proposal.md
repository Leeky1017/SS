# Proposal: issue-499-p4-backend-quality

## Why
现有后端错误处理/日志细节与 OpenSpec 规范（ss-api-surface、ss-observability、ss-state-machine）存在偏差，导致错误码不稳定、日志上下文缺失、排障成本偏高。

## What Changes
- 统一 API/Domain 的错误处理：稳定结构化错误响应（`error_code` + `message`），避免堆栈/内部异常泄露
- 对齐并补齐错误码清单（`ERROR_CODES.md`），修正不一致命名/遗漏项
- 补齐关键链路结构化日志（API 请求、状态变更、LLM 调用、Stata 执行），统一日志级别与字段
- 小范围去重与类型标注修复，确保 `ruff`/`mypy` 清洁

## Impact
- Affected specs: `openspec/specs/ss-api-surface/spec.md`, `openspec/specs/ss-observability/README.md`, `openspec/specs/ss-state-machine/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/`
- Breaking change: NO
- User benefit: 更稳定的错误码与可追踪日志，提升可维护性和可调试性
