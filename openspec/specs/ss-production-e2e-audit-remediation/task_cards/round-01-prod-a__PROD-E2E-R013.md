# [ROUND-01-PROD-A] PROD-E2E-R013: 用真实模板渲染替换 stub do-file 生成器（并归档证据）

## Metadata

- Priority: P0
- Issue: #340
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F001, F003)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

在 worker 执行链路中：

- 以 do-template library 为唯一模板来源生成 `stata.do`
- 缺失 required 参数时立即失败（结构化错误）
- 归档模板源文件、meta、params map、stdout/stderr、log 与声明 outputs（符合 ss-do-template-library）

## In scope

- 删除/替换 `stub_descriptive_v1` 专用生成路径（不再存在“仅支持 stub 模板”的生产链路）。
- 渲染逻辑必须是确定性的（同模板+同参数→同输出）。

## Out of scope

- 处理所有模板的业务语义（本任务关注“渲染与证据链正确”，业务语义交由模板库本身）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R010`、`PROD-E2E-R012`
- Soft dependencies: `PROD-E2E-R020`（依赖缺失诊断）

## Acceptance checklist

- [ ] 成功 run 的 artifacts 中包含：template source/meta/params + stata.do + stata.log + run meta
- [ ] 缺参时返回结构化错误（不生成错误的 do-file 进入 runner）
- [ ] E2E 审计旅程可跑通并确认 `template_id != stub_descriptive_v1`
