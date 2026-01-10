# [ROUND-01-PROD-A] PROD-E2E-R020: 依赖处理（ado/SSC）可诊断且可重试（不做运行时自动安装）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F002)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## Goal

当模板 meta 声明了 SSC/ado 依赖时：

- plan freeze 显式声明依赖（用于运维 preflight）
- run 前做依赖 preflight（或在失败时进行缺失依赖归因），返回结构化错误并允许修复环境后重试同一 job

本任务明确选择：**不做运行时自动安装**（避免不可控的网络/供应链/可重复性风险）。

## In scope

- 定义一个固定的错误码集合（例如 `STATA_DEPENDENCY_MISSING`）并包含缺失依赖标识符列表。
- 将缺失依赖信息写入 run error artifact，便于审计与复现。

## Out of scope

- 自动执行 `ssc install ...` 或修改 Stata 环境（交由镜像/运维处理）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R012`（plan 中必须有 deps）
- Parallelizable with: `PROD-E2E-R013`

## Acceptance checklist

- [ ] 对缺失 SSC/ado 的场景：错误可被稳定识别并产出结构化错误（含缺失项列表）
- [ ] 修复依赖后可重试同一 job 并成功（状态机与重试语义正确）
- [ ] `openspec/_ops/task_runs/ISSUE-<N>.md` 记录一次缺失依赖→修复→重试成功的证据

