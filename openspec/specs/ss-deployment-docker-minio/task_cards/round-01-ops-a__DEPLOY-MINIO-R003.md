# [ROUND-01-OPS-A] DEPLOY-MINIO-R003: 新增 Docker + MinIO uploads 本地 E2E 自检步骤/脚本

## Metadata

- Priority: P0
- Issue: #329
- Spec: `openspec/specs/ss-deployment-docker-minio/spec.md`
- Related specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`（inputs/preview）

## Problem

Docker 场景最容易踩坑的是 “presign endpoint 对外可达性” 与 “multipart finalize 所需 ETag 收集”。缺少可复现自检会导致用户在远程机部署时难以定位问题。

## Goal

提供最小可复现的手动步骤（或脚本）验证：direct + multipart presign 上传与 finalize 均可工作，且落到 inputs subsystem（manifest/preview）行为不变。

## In scope

- 新增可重复执行的自检步骤或脚本（位置由 spec 决定；建议放在 `openspec/specs/ss-deployment-docker-minio/assets/`）：
  - 启动（docker compose）
  - 创建 bundle
  - presign（direct + multipart）
  - `PUT` 上传（direct/multipart）
  - finalize（含 multipart parts 的 `{part_number, etag}`）
  - `inputs/preview` 与 `job.json.inputs.*` 验证
- 自检不要求进入 CI，但必须可在本地/远程机手动复现

## Out of scope

- 性能压测
- CI 集成

## Dependencies & parallelism

- Depends on: DEPLOY-MINIO-R002
- Can run in parallel with: 无

## Acceptance checklist

- [ ] 给出最小可复现步骤：启动 → 创建 bundle → presign → PUT 上传（direct/multipart）→ finalize → preview/manifest 验证
- [ ] 覆盖 direct 与 multipart 两条链路（multipart 包含 refresh + finalize）
- [ ] 明确记录如何收集 multipart `ETag` 并传回 finalize
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-329.md`

