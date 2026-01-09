# [ROUND-03-UPLOAD-A] UPLOAD-C002: 对象存储 port + 配置项（S3-compatible）+ fake adapter 测试策略

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-constitution/spec.md`（分层边界/依赖注入）
  - `openspec/specs/ss-security/spec.md`（不暴露 object key；脱敏）
  - `openspec/specs/ss-observability/spec.md`（结构化事件码）

## Problem

upload-sessions 需要对接外部对象存储，但实现必须保持可维护性与可测试性：域层不能绑定具体 SDK，测试不能依赖真实 S3。

## Goal

定义并实现对象存储 `port`（S3-compatible 适配），并提供可用于 pytest 并发覆盖的 fake adapter。

## In scope

- 端口定义（domain interface）：
  - direct presign（PUT）
  - multipart presign（create/upload parts/complete/abort）
  - object existence/head（用于 finalize 校验）
  - object streaming download（用于 materialize 到 job workspace `inputs/`）
- 配置项（从 `src/config.py` 显式加载）：
  - backend 选择（例如 `s3` / `stub`）
  - endpoint / region / bucket / credentials（不得散落读 env）
  - presigned TTL、multipart part size、并发限制（沿用 spec 固定名称）
- Fake adapter：
  - 内存对象存储 + 伪 presigned URL（不需要真实签名）
  - 支持并发写入/读取与 multipart 组装语义

## Out of scope

- 压测脚本与基准数据（见 UPLOAD-C006）
- 前端上传实现

## Dependencies & parallelism

- Depends on: UPLOAD-C001（合同冻结）
- Can run in parallel with: UPLOAD-C003–C006

## Acceptance checklist

- [ ] Domain 层只有 port/interface，不依赖具体 S3 SDK（依赖由 infra 注入）
- [ ] `src/config.py` 增加并加载 spec 固定的 upload/object-store 配置项
- [ ] pytest 可通过 fake object store 覆盖 direct + multipart + finalize 逻辑分支
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录 config 与测试策略

