# [ROUND-03-FE-A] FE-C002: API Client 层（typed、统一错误处理、request id 展示、可注入 base url）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Problem

如果 UI 直接散落使用 `fetch`/`axios`，很容易出现：
- API base url 不一致（尤其是 `/v1` 前缀）
- 错误处理分裂（用户看到的错误不可恢复/不可定位）
- request id 不可追踪（排障成本高）
- 类型漂移（前后端 contract 更新后不易发现破坏性变更）

## Goal

提供一个 typed、可注入 base url、统一错误处理的 API client 层，成为 FE-C003–FE-C006 的唯一 HTTP 入口，并在 UI 中可展示最后一次 request id。

## In scope

- `VITE_API_BASE_URL`（默认 `/v1`）注入能力
- 统一 headers：
  - `X-SS-Request-Id`（每次请求生成；失败时展示）
  - `X-SS-Tenant-ID`（来自 Task Code；为空则不发送）
- 统一错误模型（至少包含：`status`、`message`、`requestId`、`details`）
- 覆盖 v1 闭环 API（typed）：
  - `POST /v1/jobs`
  - `POST /v1/jobs/{job_id}/inputs/upload`
  - `GET /v1/jobs/{job_id}/inputs/preview`
  - `GET /v1/jobs/{job_id}/draft/preview`
  - `POST /v1/jobs/{job_id}/confirm`
  - `GET /v1/jobs/{job_id}`
  - `GET /v1/jobs/{job_id}/artifacts`
  - `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}`

## Out of scope

- 业务 UI 状态机与页面实现（见 FE-C003–FE-C006）
- 后端 contract 调整

## Dependencies & parallelism

- Depends on: FE-C001（`frontend/` 工程存在）
- Can run in parallel with: FE-C003–FE-C006 的 UI 布局/状态机设计（但最终落地依赖本卡）

## Acceptance checklist

- [ ] 所有对 `/v1` 的调用集中在单一 API client 模块中（UI 不直接散落 `fetch`）
- [ ] base url 可通过 `VITE_API_BASE_URL` 注入，默认 `/v1`
- [ ] 每次请求携带 `X-SS-Request-Id`，且 UI 可展示最后一次 request id（尤其是错误态）
- [ ] 错误态为可恢复（清晰提示 + 可重试），且错误模型包含 `status/message/requestId`
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

