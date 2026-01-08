# Proposal: issue-203-backend-stata-proxy-extension

## Why
SS 的 Execution Engine 已成熟，但 Proxy Layer（API + domain 业务层）相较旧版 `stata_service` 缺失关键用户能力：变量纠偏、结构化草案预览、以及冻结前的列名交叉验证。没有这三项，用户确认后的执行输入不稳定、UI 难以展示/回放、且错误变量名可能在冻结后才暴露。

## What Changes
- 新增一份 spec-first 的 OpenSpec：`openspec/backend-stata-proxy-extension/spec.md`，定义升级目标、模型字段变更、服务层改动点、API 请求/响应契约、confirm→runner 的数据流图、以及可执行的验收用例。
- 新增对应的 OpenSpec task card（含 Acceptance checklist + Evidence 入口）与 Issue run log（交付证据账本）。
- 本 Issue 为“规格补齐”任务：不修改任何 `.py` 代码文件。

## Impact
- Affected specs:
  - New: `openspec/backend-stata-proxy-extension/spec.md`
  - Task card: `openspec/specs/ss-job-contract/task_cards/backend__stata-proxy-extension.md`
- Affected code: None (spec-only)
- Breaking change: NO（本 Issue 不改运行时代码）
- User benefit: 为后续实现提供可验证契约：确认时变量纠偏、结构化草案预览响应、冻结前列名校验，避免“确认后才发现变量不存在/Do-file 不一致”。
