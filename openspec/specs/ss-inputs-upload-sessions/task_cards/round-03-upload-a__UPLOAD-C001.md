# [ROUND-03-UPLOAD-A] UPLOAD-C001: 冻结 upload-sessions v1 合同（字段/错误码/幂等/并发/限制）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-security/spec.md`
  - `openspec/specs/ss-state-machine/spec.md`（幂等/并发口径）

## Problem

大文件与高并发上传需要严格的“契约先行”：字段集合、错误码、幂等与并发语义必须在实现前冻结，否则前端与存储适配会被频繁返工。

## Goal

冻结 `ss-inputs-upload-sessions` v1 合同，确保 API、域模型与测试口径一致且可审计。

## In scope

- v1 API 合同冻结：
  - bundle endpoints
  - `POST /v1/jobs/{job_id}/inputs/upload-sessions`（direct/multipart）
  - `POST /v1/upload-sessions/{upload_session_id}/refresh-urls`
  - `POST /v1/upload-sessions/{upload_session_id}/finalize`
- 错误码集合冻结（至少覆盖）：
  - `AUTH_REQUIRED` / `AUTH_INVALID` / `AUTH_EXPIRED`
  - `BUNDLE_NOT_FOUND` / `FILE_NOT_FOUND`
  - `INPUT_UNSUPPORTED_FORMAT` / `INPUT_FILENAME_UNSAFE`
  - `UPLOAD_SESSION_NOT_FOUND` / `UPLOAD_SESSION_EXPIRED`
  - `UPLOAD_PARTS_INVALID` / `UPLOAD_INCOMPLETE`
  - `CHECKSUM_MISMATCH`（retryable）
- 幂等与并发语义冻结：
  - finalize 强幂等（重复/并发调用返回一致结果）
  - refresh 的幂等口径（同 part_number 可重复取新 URL）
- 限制项与配置项名称冻结（由 spec 定义的 env keys）

## Out of scope

- 任何代码实现
- 对象存储 provider 选型与接入（见 UPLOAD-C002）

## Dependencies & parallelism

- Depends on: 无（纯契约卡）
- Can run in parallel with: UPLOAD-C002–C006（实现卡）

## Acceptance checklist

- [ ] `openspec/specs/ss-inputs-upload-sessions/spec.md` 明确并冻结字段、错误码、幂等/并发语义与限制项
- [ ] 与现有 `inputs/manifest.json`（schema_version=2）与 `inputs/preview` 语义对齐
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录评审结论与关键决策

