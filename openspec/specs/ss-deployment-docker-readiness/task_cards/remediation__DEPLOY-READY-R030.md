# [DEPLOY-READY] DEPLOY-READY-R030: 补充缺失的 do-template（如需：宽表/长表/面板数据处理）

## Metadata

- Priority: P1
- Issue: #388
- Spec: `openspec/specs/ss-deployment-docker-readiness/spec.md`
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Problem

如果审计发现 do-template 对宽表/长表/面板数据的关键路径覆盖不足，生产部署将出现“数据形态不匹配 → 模板失败”的系统性风险。

## Goal

基于审计结果补齐必要的 do-template 能力，使 SS 在生产部署中对目标数据形态具备可验收的覆盖。

## In scope

- 根据 DEPLOY-READY-R001 的能力矩阵补齐缺口模板（新增或增强）
- 为新增/增强模板补齐 meta（inputs/outputs/parameters/dependencies）
- 增加最小可复现的 smoke/audit 用例（以便回归）

## Out of scope

- 不在本卡扩展到与生产部署无关的“长尾模型/长尾可视化”

## Dependencies & parallelism

- Depends on: DEPLOY-READY-R001
- Can run in parallel with: DEPLOY-READY-R031（输出格式器整改）

## Acceptance checklist

- [ ] 缺口模板已补齐且 meta 合同完整（inputs/outputs/parameters/deps）
- [ ] 能力矩阵更新并标注新增覆盖点
- [ ] 至少一个可复现回归路径（smoke suite 或 pytest 集成测试）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md`
