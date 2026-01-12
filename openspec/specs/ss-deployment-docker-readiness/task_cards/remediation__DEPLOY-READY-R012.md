# [DEPLOY-READY] DEPLOY-READY-R012: 定义并落地 Stata 安装/配置方案（镜像内 or 宿主挂载）

## Metadata

- Priority: P0
- Issue: #390
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-ports-and-services/spec.md`

## Problem

worker 依赖 Stata 执行 do-template，但生产部署场景下 Stata 的安装与 license/路径/挂载不明确会直接阻断上线：
- 镜像内安装：构建流程与 license 管理复杂
- 宿主挂载：需要固定挂载路径与 `SS_STATA_CMD` 注入策略

## Goal

形成并落地一套可执行、可验收的 Stata provisioning 方案，至少满足：
- worker 启动前能明确得到 `SS_STATA_CMD`
- 失败时明确报错（不可 silent fallback）
- 在 Docker compose 环境中可复现

## In scope

- 决策并文档化：镜像内安装 vs 宿主挂载（可支持两种，但必须给出主推荐路径）
- 明确 `SS_STATA_CMD` 的配置口径与安全约束
- 给出可执行的 compose 配置示例（路径/挂载/环境变量）

## Out of scope

- 不在本卡解决 Stata license 的商业获取与合规流程

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R003（gap 分析）
- Can run in parallel with: DEPLOY-READY-R010, DEPLOY-READY-R011

## Acceptance checklist

- [ ] 给出明确的 Stata provisioning 方案与操作步骤（包含 `SS_STATA_CMD` 口径）
- [ ] Docker compose 环境中可复现（worker 启动链路清晰，缺配置时 fail fast）
- [ ] 明确安全/合规边界（不在仓库内传播 license/installer）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-390.md`
