# [DEPLOY-READY] DEPLOY-READY-R001: 审计 do-template 库的数据处理能力（宽表/长表/面板数据）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Problem

生产部署要可预测、可验收，但当前 do-template 库对以下数据形态的真实覆盖能力不透明：
- 宽表（many columns）
- 长表（long / tidy）
- 面板数据（entity/time + panel transforms/estimators）

缺少可审计的“能力矩阵”会导致：上线后才发现模板不适配数据形态，形成不可控的生产失败。

## Goal

产出一份基于 `assets/stata_do_library/` 的可审计能力报告，明确：
- 当前模板覆盖哪些数据形态（按模板/模块/家族归类）
- 关键假设（例如必须包含哪些列、是否要求 panel id / time id）
- 已知缺口与风险分级，并把缺口映射到后续整改卡（例如 DEPLOY-READY-R030）

## In scope

- 深入审计 `assets/stata_do_library/do/` 与对应 `do/meta/*.meta.json`
- 归纳每个模板对数据形态的要求与前置检查（如有）
- 形成“宽/长/面板能力矩阵”与结论（含证据指针：模板 id + 关键代码片段位置）

## Out of scope

- 不在本卡直接新增/改动模板（由 DEPLOY-READY-R030 承接）
- 不在本卡落地 Docker/worker 变更

## Dependencies & parallelism

- Depends on: none
- Can run in parallel with: DEPLOY-READY-R002, DEPLOY-READY-R003

## Acceptance checklist

- [ ] 产出能力矩阵（宽/长/面板）并明确每个结论对应的模板证据
- [ ] 明确“必须支持/可选支持/不支持”的边界，并列出风险项与建议处置
- [ ] 把缺口映射到整改任务（至少覆盖 DEPLOY-READY-R030）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md`

