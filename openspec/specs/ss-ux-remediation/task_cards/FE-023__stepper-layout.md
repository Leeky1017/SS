# Task Card: FE-023 Stepper layout

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Stepper 与标题脱节，整体布局层级不清晰。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/layout.css`
- `frontend/src/App.tsx`

## 解决方案

1. 调整 header/stepper 的布局关系
2. 确保在不同宽度下对齐一致

## 验收标准

- [ ] 标题与 stepper 对齐且层级清晰
- [ ] 窄屏下不挤压变形

## Dependencies

- 无
