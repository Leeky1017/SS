# Task Card: FE-011 Empty state design

- Priority: P2-MEDIUM
- Area: Frontend / UX
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无空状态设计，列表/表格为空时缺乏引导。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/status/Status.tsx`
- `frontend/src/features/admin/pages/AdminJobsPage.tsx`

## 解决方案

1. 为关键空状态提供可操作引导（下一步/刷新/去上传）
2. 空状态文案进入 i18n

## 验收标准

- [ ] 空状态包含明确下一步操作按钮
- [ ] 空状态文案可读且一致

## Dependencies

- 无
