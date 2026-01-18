# Proposal: issue-536-wave-2-core-ux

## Why
Wave 2 核心 UX 存在“层级不清 + 交互无反馈 + 刷新丢输入”的组合问题：宽屏内容区过窄、表格与控件反馈不明显、请求等待缺少全局指示器、Stepper 无标签不可回退、Step3 表单刷新后丢失，导致用户反复试错与重复劳动。

## What Changes
- CSS/布局：主内容区宽屏扩展到 960px，表格 hover 更清晰，select 样式一致化，disabled 按钮状态更明确，表格高度策略统一，Stepper 与标题层级更清晰，引导卡片尺寸统一，预览信息行更易扫读。
- 交互反馈：Tab 切换提供明确的交互反馈；Stepper 展示步骤名称并允许回到已完成步骤；引入全局 Loading 指示器（>300ms）；关键区域增加 skeleton loading。
- 状态管理：扩展 `frontend/src/state/storage.ts`，实现 per-job 的 Step2 sheet 选择与 Step3 表单草稿持久化，并在 reset/confirm/401/403 等路径进行明确清理，避免跨任务污染。

## Impact
- Affected specs:
  - `openspec/specs/ss-ux-remediation/task_cards/FE-001__navigation-feedback.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-002__stepper-redesign.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-006__global-loading-state.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-007__table-hover-feedback.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-009__select-styling.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-010__button-disabled-state.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-019__main-content-width.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-020__table-height-consistency.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-023__stepper-layout.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-024__guide-card-sizing.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-025__preview-info-layout.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-032__localstorage-cleanup.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-035__sheet-selection-memory.md`
  - `openspec/specs/ss-ux-remediation/task_cards/FE-038__state-persistence.md`
  - `openspec/specs/ss-frontend-architecture/spec.md`
- Affected code:
  - `frontend/src/App.tsx`
  - `frontend/src/main.tsx`
  - `frontend/src/api/client.ts`
  - `frontend/src/state/storage.ts`
  - `frontend/src/features/step1/*`
  - `frontend/src/features/step2/*`
  - `frontend/src/features/step3/*`
  - `frontend/src/styles/layout.css`
  - `frontend/src/styles/components.css`
- Breaking change: NO
- User benefit: 宽屏可读性提升、等待更可感知、导航更可回退、刷新不丢 Step3 高投入输入，减少误操作与重复劳动。
