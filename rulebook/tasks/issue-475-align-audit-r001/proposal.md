# Proposal: issue-475-align-audit-r001

## Why
SS 的前后端 API 契约当前缺少一次“从头到脚”的对齐审计，容易导致前端调用与后端实现/Schema 漂移、以及隐式透传数据引发的 500 风险。

## What Changes
- 新增 `Audit/api_contract_audit_report.md`：结构化列出所有 API 端点检查结论、不一致点与可执行修复方案。
- 不修改任何业务代码与接口实现（本任务仅交付审计报告）。

## Impact
- Affected specs: none（审计产物）
- Affected code: none
- Breaking change: NO
- User benefit: 明确前后端契约差异与风险点，减少后续对齐/修复的返工成本
