# [ROUND-01-OPS-A] DEPLOY-MINIO-R001: 定义 Docker + MinIO（S3-compatible）uploads 部署规范（spec-first）

## Metadata

- Priority: P0
- Issue: #329
- Spec: `openspec/specs/ss-deployment-docker-minio/spec.md`
- Related specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md`
  - `openspec/specs/ss-constitution/spec.md`

## Problem

生产链路已禁止 runtime fake object store backend，但用户在 Docker 部署时不希望依赖云厂商对象存储。需要一套“生产可用”的 S3-compatible 部署方案，使 upload sessions 仍走 direct/multipart presign + finalize，且上传字节不穿过 SS API。

## Goal

新增 OpenSpec：在 Docker 环境里用 MinIO（S3-compatible）作为 upload sessions 的对象存储后端，明确配置键、关键约束与最小端到端验证场景。

## In scope

- 新增 spec：`openspec/specs/ss-deployment-docker-minio/spec.md`
- 在 spec 中明确引用 `src/config.py` 的 upload 相关 env keys
- 强调关键约束：presigned URL 的 host 必须为客户端可达且不能改写（避免 internal/external endpoint 不一致破坏签名）
- 场景至少包含：
  - Docker + MinIO direct upload session works end-to-end
  - Docker + MinIO multipart upload session works end-to-end (refresh + finalize)
- 失败模式至少包含：
  - production startup fails when S3 config missing（错误码稳定：`OBJECT_STORE_CONFIG_INVALID`）

## Out of scope

- 不新增/恢复 runtime fake backend
- 不修改 upload sessions 的领域语义/字段合同
- 不在本卡里落地 docker-compose 与自检脚本（由 R002/R003 承接）

## Dependencies & parallelism

- Depends on: 无（纯文档/spec 卡）
- Can run in parallel with: R002/R003

## Acceptance checklist

- [x] 新增 `openspec/specs/ss-deployment-docker-minio/spec.md` 且通过 `openspec validate --specs --strict --no-interactive`
- [x] spec 明确列出 upload 相关 env keys（以 `src/config.py` 为权威来源）
- [x] spec 明确强调 presigned URL host 必须客户端可达且不可改写的约束
- [x] spec 包含 direct + multipart 两个 E2E 场景与一个生产缺配置失败场景
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-329.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/330
- Added `ss-deployment-docker-minio` OpenSpec with direct/multipart scenarios and a production missing-config failure scenario.
- Added task cards R001–R003 to drive deploy assets and a manual e2e self-check workflow.
- Run log: `openspec/_ops/task_runs/ISSUE-329.md`
