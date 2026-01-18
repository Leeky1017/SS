# Proposal: issue-534-fe-043-actionable-errors

## Why
当前前端错误面板仅展示红字与参考编号，缺少“下一步怎么做”的可操作引导，用户在关键流程被阻断时无法自助补全并继续。

## What Changes
- ErrorPanel：让 `request_id` 可复制，并为已知错误展示可执行操作入口。
- Step3：针对 `PLAN_FREEZE_MISSING_REQUIRED` 提供补全 UI（选择缺失的 ID/Time 变量）并支持一键重试确认。

## Impact
- Affected specs: `openspec/specs/ss-ux-remediation/task_cards/FE-043__actionable-errors.md`
- Affected code: `frontend/src/components/ErrorPanel.tsx`, `frontend/src/features/step3/*`
- Breaking change: NO
- User benefit: 出错时可按提示补全并继续流程，减少卡死与重复尝试。
