# Proposal: issue-18-arch-t021

## Why
需要一个最小但权威的 job 查询端点，支撑轮询与调试，并为后续 artifacts/run trigger 等 API 扩展提供稳定入口。

## What Changes
- 新增 `GET /jobs/{job_id}`：返回权威 status、timestamps、draft 摘要、artifacts 索引摘要、最近一次 run attempt（如有）。
- API 层保持薄：只做参数/响应组装，读取与摘要计算放在 domain service，通过 `JobStore` 持久化读取。
- 错误保持结构化（`error_code` + `message`），包含 `JOB_NOT_FOUND` / `JOB_DATA_CORRUPTED` 等。

## Impact
- Affected specs: `openspec/specs/ss-api-surface/spec.md`, `openspec/specs/ss-job-contract/spec.md`
- Affected code: `src/api/jobs.py`, `src/api/schemas.py`, `src/domain/job_service.py`
- Breaking change: NO
- User benefit: 客户端可通过单一端点获取 job 最小权威摘要，便于轮询、排错与集成。
