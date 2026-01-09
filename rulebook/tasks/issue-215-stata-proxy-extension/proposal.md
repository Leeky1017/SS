# Proposal: issue-215-stata-proxy-extension

## Why
SS 新后端的 Proxy Layer（API + domain service）缺少旧版 `stata_service` 已验证的关键交互语义：用户变量纠偏、结构化草案预览、以及冻结前的列名校验，导致确认/冻结链路不可复现、不可审计、且容易把不存在的变量推进到可执行阶段。

## What Changes
- 扩展 API 与 domain schema：confirm 持久化 `variable_corrections` / `default_overrides`；draft preview 返回结构化字段。
- 实现 variable corrections 清洗与 token-boundary 安全替换，并在 confirm→freeze→queue 链路一致应用。
- 在 plan freeze 阶段做“纠偏后变量名 ∩ primary dataset 列名”的交叉验证；失败返回稳定错误码 `CONTRACT_COLUMN_NOT_FOUND` 且不进入 `queued`。

## Impact
- Affected specs: `openspec/specs/backend-stata-proxy-extension/spec.md`
- Affected code: `src/api/`, `src/domain/`, `src/infra/plan_exceptions.py`, tests
- Breaking change: NO (保持 `draft_text` 向后兼容；confirm 增量字段有默认值)
- User benefit: 更可控的确认/冻结体验；冻结前阻断无效变量；UI 可直接用结构化预览字段渲染与回放。
