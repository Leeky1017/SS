# [DEPLOY-READY] DEPLOY-READY-R011: docker-compose.yml 增加 Worker 服务定义

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-deployment-docker-minio/spec.md`
  - `openspec/specs/ss-worker-queue/spec.md`
  - `openspec/specs/ss-ports-and-services/spec.md`

## Problem

当前 Docker compose 资产缺少 worker 服务，导致：
- `POST /v1/jobs/{job_id}/run` 只能入队，无法完成执行闭环
- 无法进行 Docker 端到端验证（E2E）

## Goal

在 `docker-compose.yml` 中定义 `ss-worker` 服务，与 `ss-api` 形成完整拓扑（并可依赖 MinIO 作为对象存储），从而支持生产部署与 E2E 验证。

## In scope

- `docker-compose.yml` 新增 `ss-worker` 服务（与 `ss-api` 同镜像）
- 共享 jobs/queue 持久化 volumes（与 API 对齐）
- 明确 `SS_STATA_CMD` 与 `SS_DO_TEMPLATE_LIBRARY_DIR` 的注入方式（环境变量/挂载）

## Out of scope

- 不在本卡决定 Stata 采用“镜像内安装”还是“宿主挂载”（由 DEPLOY-READY-R012 决策）
- 不在本卡增加额外外部依赖（例如 Postgres/Redis），除非被明确选为生产基线

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R010（镜像构建入口）
- Can run in parallel with: DEPLOY-READY-R012

## Acceptance checklist

- [ ] `docker-compose.yml` 包含 `minio` + `ss-api` + `ss-worker` 的最小生产拓扑
- [ ] `ss-worker` 与 `ss-api` 共享 jobs/queue 的持久化存储并保持路径一致
- [ ] `docker-compose up` 后 worker 能启动（配置齐全时）并可处理队列任务
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md`

