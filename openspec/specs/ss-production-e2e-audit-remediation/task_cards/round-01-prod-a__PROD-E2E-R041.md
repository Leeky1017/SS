# [ROUND-01-PROD-A] PROD-E2E-R041: 移除 stub LLM provider（runtime 不再支持 stub）

## Metadata

- Priority: P0
- Issue: #316
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F004)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

运行时不再存在 `SS_LLM_PROVIDER=stub` 与 `StubLLMClient` 这条链路，避免任何环境“默认跑 stub”。

## In scope

- 删除 runtime 的 stub LLM provider 实现与 factory 分支。
- 配置加载不再默认为 stub；必须显式选择真实 provider 并提供必需配置。
- 测试如需 fake LLM，使用 `tests/**` 内的 fake 实现或注入（不保留 runtime stub）。

## Out of scope

- 更换 LLM provider SDK（保持 openai-compatible 方案）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R040`（production gate）
- Soft dependencies: `PROD-E2E-R011`（模板选择会用到 LLM）

## Acceptance checklist

- [ ] `SS_LLM_PROVIDER=stub` 不再被支持（启动/运行时明确失败且错误码稳定）
- [ ] 生产 E2E 审计证据中 LLM meta 仍可审计并包含真实 model 名
- [ ] 单元测试与集成测试不依赖 runtime stub（使用显式注入的 fake）
