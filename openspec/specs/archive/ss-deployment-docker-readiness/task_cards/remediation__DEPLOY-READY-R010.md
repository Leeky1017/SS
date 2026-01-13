# [DEPLOY-READY] DEPLOY-READY-R010: 新增 Dockerfile（构建 SS API + Worker 生产镜像）

## Metadata

- Priority: P0
- Issue: #387
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-ports-and-services/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-worker-queue/spec.md`

## Problem

缺少生产镜像构建入口会导致生产部署无法标准化、无法在 CI/发布链路中复现，也无法进行 e2e 验证与回滚。

## Goal

在仓库根目录提供可复现的 `Dockerfile`，用于构建 SS 生产镜像，并支持：
- 以同一个镜像分别启动 API 与 Worker（不同 command/entrypoint）
- 明确依赖锁定输入（requirements.txt 或 lock file）
- 明确 Stata provisioning 策略（由 DEPLOY-READY-R012 定义）

## In scope

- 新增 `Dockerfile`（支持生产构建；API/worker 可分开启动）
- （如需要）新增 `.dockerignore`
- 明确镜像运行时依赖的 env keys（例如 `SS_STATA_CMD`、jobs/queue 路径等）

## Out of scope

- 不在本卡强制把 Stata 打包进镜像（由 DEPLOY-READY-R012 决策与落地）
- 不在本卡发布镜像到 registry

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R003（gap 分析建议先完成）
- Can run in parallel with: DEPLOY-READY-R011, DEPLOY-READY-R020

## Acceptance checklist

- [x] 仓库根目录新增 `Dockerfile`，可在无交互环境中构建成功
- [x] 镜像可分别启动 API 与 Worker（不要求真正跑 Stata，但启动链路明确）
- [x] 依赖锁定策略明确（requirements.txt 或 lock file）且被 Dockerfile 使用
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-387.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/393
- Run log: `openspec/_ops/task_runs/ISSUE-387.md`
- Summary:
  - Added repo-root `Dockerfile` (single image for API + worker).
  - Added `.dockerignore` for deterministic build contexts.
  - Documented validation commands and environment constraints in the run log.
