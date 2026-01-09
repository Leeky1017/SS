# [ROUND-03-UPLOAD-A] UPLOAD-C004: upload-sessions（direct + multipart）签发 + 刷新策略

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-security/spec.md`
  - `openspec/specs/ss-observability/spec.md`
  - `openspec/specs/ss-multi-tenant/spec.md`

## Problem

大文件上传需要 presigned URL，且必须支持 multipart 以提高可靠性与并发吞吐；URL 过期需要明确刷新策略，否则长传会中断。

## Goal

实现 upload session 签发（direct/multipart）与 refresh endpoint，满足 spec 的字段、过期与限制约束。

## In scope

- `POST /v1/jobs/{job_id}/inputs/upload-sessions`
  - server-controlled strategy selection（阈值来自 config）
  - direct：返回 `presigned_url`
  - multipart：返回 `presigned_urls[]` + `part_size`
- `POST /v1/upload-sessions/{upload_session_id}/refresh-urls`
  - 支持按 `part_numbers` 刷新子集
  - 过期策略固定：<= 15 min（config 上限）
- 限制与防滥用：
  - max sessions per job
  - multipart part size 范围 + max parts
- 结构化日志事件码（至少）：
  - `SS_UPLOAD_SESSION_CREATE`
  - `SS_UPLOAD_SESSION_REFRESH`

## Out of scope

- finalize materialize（见 UPLOAD-C005）
- 前端上传并发控制（前端卡另开）

## Dependencies & parallelism

- Depends on: UPLOAD-C001, UPLOAD-C002, UPLOAD-C003
- Can run in parallel with: UPLOAD-C005（只要 finalize 以 session store 为边界）

## Acceptance checklist

- [ ] direct + multipart 两条路径都有 pytest 覆盖（可用 fake object store）
- [ ] refresh 可工作且不会返回过期 TTL > 15 min
- [ ] 无 token 时不得创建/刷新 session
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键参数与并发维度

