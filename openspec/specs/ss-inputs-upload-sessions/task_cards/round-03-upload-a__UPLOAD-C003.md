# [ROUND-03-UPLOAD-A] UPLOAD-C003: bundle endpoints + 文件角色模型（多文件/重复名策略）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-multi-tenant/spec.md`
  - `openspec/specs/ss-security/spec.md`

## Problem

upload-sessions 必须有一个“声明层”来承载多文件、角色、重复文件名等元数据，否则 session 创建与 finalize 无法稳定引用。

## Goal

实现 bundle endpoints，并落盘可恢复的 bundle 状态：文件角色模型 + `file_id` 稳定引用 + 重复 filename 策略。

## In scope

- `POST /v1/jobs/{job_id}/inputs/bundle`
  - 声明 `files[]`（filename/size_bytes/role/mime_type）
  - 返回 `bundle_id` 与 `files[].file_id`
- `GET /v1/jobs/{job_id}/inputs/bundle`
  - 支持刷新恢复（前端可重进）
- 重复 filename 策略（按 spec）：允许；用 `file_id` 区分；不做自动重命名
- 多租户隔离：
  - tenant header 与持久化隔离一致

## Out of scope

- upload-sessions 签发（见 UPLOAD-C004）
- finalize materialize（见 UPLOAD-C005）

## Dependencies & parallelism

- Depends on: UPLOAD-C001
- Can run in parallel with: UPLOAD-C002 / UPLOAD-C004

## Acceptance checklist

- [ ] bundle endpoints 已实现且严格按 spec 字段与错误码返回
- [ ] 重复 filename 的 bundle 可创建成功，并可通过 `file_id` 进行后续 session 创建
- [ ] Bundle 状态可恢复（刷新后 GET 返回一致）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录 API 示例与测试

