# [DEPLOY-READY] DEPLOY-READY-R003: 审计当前 Docker 部署资产与生产部署需求差距（compose/API/worker/Stata）

## Metadata

- Priority: P0
- Issue: #371
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-deployment-docker-minio/spec.md`
  - `openspec/specs/ss-ports-and-services/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-worker-queue/spec.md`

## Problem

SS 需要在远程服务器上通过 Docker 进行生产部署，但当前仓库缺少明确且可验收的“生产部署资产”：
- 仓库根目录缺少 `Dockerfile`
- 现有 compose 资产只覆盖 API（缺少 worker）
- Stata 的安装/挂载/配置方案未形成可执行口径

## Goal

产出一份面向生产部署的差距清单（gap list）与最小整改路径，明确：
- 当前已有资产（例如 `ss-deployment-docker-minio` 下的 compose）的可复用部分
- 与生产需求相比的缺口（Dockerfile / ss-worker / volumes / env keys / Stata strategy）
- 把缺口映射为后续整改卡（DEPLOY-READY-R010/R011/R012/R020/R090）

## In scope

- 盘点仓库现有 Docker/compose 相关资产与约束
- 对照 `ss-deployment-docker-readiness` 的 requirements 做 gap 分析
- 输出可执行的整改序列与并行建议

## Out of scope

- 不在本卡直接新增 Dockerfile/compose（由整改卡承接）
- 不要求本卡完成一次真实生产部署

## Dependencies & parallelism

- Depends on: none
- Can run in parallel with: DEPLOY-READY-R001, DEPLOY-READY-R002

## Acceptance checklist

- [x] 输出 gap list（按 requirement 编号逐项对照），并标注优先级与推荐归属任务
- [x] 明确 compose 需要包含的最小拓扑（MinIO + ss-api + ss-worker）与关键 volumes
- [x] 明确 Stata strategy 的决策点与风险（license/路径/挂载/SS_STATA_CMD）
- [x] Evidence: `openspec/_ops/task_runs/ISSUE-371.md`

## Completion

- PR: https://github.com/Leeky1017/SS/pull/378
- Delivered a numbered gap list (DR-REQ-01..09) with priority + mapped remediation cards.
- Defined minimal production compose topology (minio + ss-api + ss-worker) and key volumes.
- Documented Stata provisioning decision points/risks and a minimal remediation sequence (R010/R020/R012/R011 → R090).
- Run log: `openspec/_ops/task_runs/ISSUE-371.md`
