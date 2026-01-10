# [ROUND-01-OPS-A] DEPLOY-MINIO-R002: 增加可复用 docker-compose 部署资产（MinIO + SS）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-deployment-docker-minio/spec.md`
- Related specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md`
  - `openspec/specs/ss-ports-and-services/spec.md`

## Problem

仅有文字说明不足以落地；需要一个可复用、可复制的 docker-compose（或等价部署资产）来保证 MinIO 独立服务、bucket 初始化、端口暴露与 endpoint 可达性。

## Goal

在仓库中新增可复用的 Docker 部署资产，用于在单机 Docker 环境启动 MinIO（S3-compatible）与 SS，并以最小配置满足 upload sessions 的 presign/finalize 链路。

## In scope

- 在仓库中新增部署资产（位置由 spec 决定；建议放在 `openspec/specs/ss-deployment-docker-minio/assets/`）：
  - `docker-compose.yml`（MinIO + SS）
  - `.env.example`（最小可运行配置样例）
- MinIO 作为独立 service：
  - 持久化卷（data）
  - 自动创建 `SS_UPLOAD_S3_BUCKET`（可用 init container 或 `mc`）
- SS 服务配置：
  - `SS_UPLOAD_OBJECT_STORE_BACKEND=s3`
  - `SS_UPLOAD_S3_ENDPOINT` 选用对客户端可达且与签名一致的 host（避免 internal/external mismatch）
- 文档仅允许指针（如需在 `docs/` 增加入口，必须只做链接/入口，不复制规范内容）

## Out of scope

- 任何 runtime fake backend
- 代码改动（除非另开卡并先在 spec 中新增 requirement+scenario）

## Dependencies & parallelism

- Depends on: DEPLOY-MINIO-R001
- Can run in parallel with: DEPLOY-MINIO-R003

## Acceptance checklist

- [ ] 新增可复用 docker-compose 资产（含 MinIO 独立服务与 bucket 初始化）
- [ ] `docker compose up` 后 MinIO console 可访问，bucket 已存在
- [ ] SS 可启动并能返回 `/health/live`
- [ ] 资产与规范均由 `openspec/specs/**` 管理；`docs/` 如新增仅为指针入口
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-329.md`
