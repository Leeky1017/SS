# [ROUND-03-UPLOAD-A] UPLOAD-C005: finalize 幂等语义 + 纳入 inputs/manifest.json + fingerprint 规则

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`（inputs/preview）
  - `openspec/specs/ss-state-machine/spec.md`（幂等/可重试）

## Problem

finalize 是把对象存储里的上传结果“纳入 SS inputs 体系”的唯一入口：如果幂等与并发语义不严谨，会导致 manifest 损坏、fingerprint 不稳定、preview 读不到文件。

## Goal

实现 finalize：强幂等/可并发/可重试，并把文件 materialize 到 job workspace `inputs/`，同时更新 `inputs/manifest.json`（schema_version=2）与 `job.json.inputs.fingerprint`（bundle 级）。

## In scope

- `POST /v1/upload-sessions/{upload_session_id}/finalize`
  - direct：视为单 part（part_number=1）
  - multipart：校验 parts[]（part_number/etag），完成 multipart assemble
  - 校验与错误码：`CHECKSUM_MISMATCH` 标记 retryable
- materialize 规则：
  - 写入 `inputs/<dataset_key>.<ext>`（path-safe；不使用用户 filename）
  - 更新/写入 `inputs/manifest.json`（schema_version=2 datasets[]）
  - 更新 `job.json.inputs.manifest_rel_path` 与 `job.json.inputs.fingerprint`
  - inputs 产物纳入 artifacts_index（manifest + dataset）
- fingerprint 规则（按 spec 固定算法）

## Out of scope

- 预览解析器本身的改造（沿用现有 preview 语义）
- 后续对 object-store 原地读取（不落盘 inputs/）的优化

## Dependencies & parallelism

- Depends on: UPLOAD-C001, UPLOAD-C002, UPLOAD-C003, UPLOAD-C004
- Can run in parallel with: UPLOAD-C006（测试与压测计划）

## Acceptance checklist

- [ ] finalize 重复/并发调用返回一致结果（pytest anyio 并发覆盖）
- [ ] finalize 成功后 `GET /v1/jobs/{job_id}/inputs/preview` 可读到 primary dataset
- [ ] manifest schema_version=2 与 fingerprint 规则按 spec 固定实现
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键错误码与幂等设计

