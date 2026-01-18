# Task Card: FE-048 Screen reader support

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

屏幕阅读器不支持，缺少语义与 aria 标注。

## 技术分析

- 现状：
  - 可访问名称不足：部分交互控件仅靠视觉布局表达含义/状态（例如 header tab 的选中态只靠 `active` class），缺少明确的 aria 语义（如 `aria-current`/`aria-selected`、`role="tablist"` 等）。
  - 缺少 `aria-live`：请求错误、轮询 pending、自动刷新等关键状态变化只在视觉上更新，读屏器无法及时获知“已更新/失败/下一步可做什么”。
  - 表格语义不完整：多处 `<table>` 未提供 `<caption>`，表头 `<th>` 未声明 `scope`，并存在空表头（例如下载列表的第二列），导致读屏器难以建立列/行关系。
  - 对话框可达性不足：模态框虽设置了 `role="dialog"`/`aria-modal`，但缺少可感知的标题关联（`aria-labelledby`）与初始焦点管理。
- 影响：读屏用户难以理解页面结构、表格内容与动态状态，无法独立完成主流程。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/App.tsx`
  - `frontend/src/components/ErrorPanel.tsx`
  - `frontend/src/features/status/Status.tsx`
  - `frontend/src/features/step3/panelsBase.tsx`
  - `frontend/src/features/step3/panelsConfirm.tsx`

## 解决方案

1. 补充语义标签与 aria 属性
2. 为动态区域提供 aria-live

## 验收标准

- [ ] 关键页面可被读屏器理解
- [ ] 无 aria 误用导致噪音

## Dependencies

- 无
