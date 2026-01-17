# Task Card: FE-020 Table height consistency

- Priority: P2-MEDIUM
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

表格高度限制不统一，用户需要在多个小窗口反复滚动。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`
- `frontend/src/features/admin/pages/AdminJobsPage.tsx`

## 解决方案

1. 统一 data-table-wrap 的 maxHeight 策略
2. 在不同页面解释并遵循同一规则

## 验收标准

- [ ] 关键页面表格高度策略一致
- [ ] 滚动边界与可读性提升

## Dependencies

- 无
