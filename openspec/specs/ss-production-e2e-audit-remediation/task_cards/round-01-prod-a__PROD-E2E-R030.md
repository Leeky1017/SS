# [ROUND-01-PROD-A] PROD-E2E-R030: Plan freeze 缺参必须结构化失败（绑定契约门禁）

## Metadata

- Priority: P0
- Issue: #341
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F003)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## Goal

把 “缺参 → 结构化错误” 作为 plan-freeze 的硬门禁，避免：

- draft 中存在 blocking unknowns 仍可 freeze/run
- template meta required params 缺失仍可进入 worker

## In scope

- plan freeze 必须同时检查：
  - v1 draft blockers（stage questions + open_unknowns 中 blocking 项）
  - template meta required params（基于参数规格）
- 失败时返回结构化错误，包含：
  - error_code（固定集合）
  - missing fields/params 列表
  - 可用于重试的 next action（例如通过 confirm/patch 填参）

## Out of scope

- 交互式问答 UI（本任务只定义与实现服务端门禁与错误模型）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R011`、`PROD-E2E-R012`
- Parallelizable with: `PROD-E2E-R013`

## Acceptance checklist

- [ ] 构造缺参输入时，plan freeze 必定失败且返回结构化错误（单元测试 + 集成测试）
- [ ] 修复缺参后，plan freeze 成功且 plan 契约完整
- [ ] 审计 spec 的 “Missing parameters yield structured errors” 场景可 PASS
