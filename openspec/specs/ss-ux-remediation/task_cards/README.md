# Task cards: ss-ux-remediation

本目录将 SS UX 全面修复拆成**独立可执行**的任务卡（frontend + backend + E2E）。

约定（强制）：
- 每张卡必须包含：问题描述 / 技术分析 / 解决方案 / 验收标准 / 优先级（P0/P1/P2/P3）
- 允许写 `Dependencies`（涉及 API 契约/生成流程时必须写清）

## Frontend (FE-001..FE-064)

- 交互反馈与导航：FE-001..FE-006, FE-015, FE-023, FE-039, FE-063
- 显示与布局：FE-007, FE-009..FE-014, FE-019..FE-025, FE-050..FE-052
- 状态管理与恢复：FE-032..FE-038, FE-041, FE-055
- 异常处理与容错：FE-040, FE-043, FE-053, FE-054, FE-058
- 可访问性：FE-047..FE-049
- 性能与可信感：FE-057, FE-059..FE-062, FE-064

## Backend (BE-001..BE-009)

后端任务卡涉及 API schema/route 的变更时，必须遵循契约流程：
后端先改 → `scripts/contract_sync.sh generate` 生成前端 types → 再改前端调用/页面。

## E2E

- E2E-001：面板回归完整工作流（含错误可操作性场景）

