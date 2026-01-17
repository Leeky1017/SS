# Task Card: FE-013 Micro-animations

- Priority: P3-LOW
- Area: Frontend / Polish
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

动画效果单一，缺少微交互提升反馈感。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/theme.css`
- `frontend/src/styles/components.css`

## 解决方案

1. 为 hover/press/enter 添加统一过渡
2. 尊重 prefers-reduced-motion 并避免过度动画

## 验收标准

- [ ] 交互元素 hover/press 有一致过渡
- [ ] reduce motion 时动画可降级/关闭

## Dependencies

- 无
