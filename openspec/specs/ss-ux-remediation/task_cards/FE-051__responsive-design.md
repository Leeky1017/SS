# Task Card: FE-051 Responsive design

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无响应式设计，窄屏体验差。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/layout.css`

## 解决方案

1. 为关键断点添加布局调整
2. 保证触摸目标大小下限

## 验收标准

- [ ] ≤768px 宽度下不崩坏
- [ ] 触摸目标 ≥ 44px

## Dependencies

- 无
