# Task Card: FE-007 Table hover feedback

- Priority: P2-MEDIUM
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

表格悬停反馈弱，难以对齐当前行/列。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 增强表格 hover 样式（light/dark 都清晰）
2. 保证 hover 不依赖颜色单一信号

## 验收标准

- [ ] hover 行在浅色/深色模式下均明显可见
- [ ] hover 不影响可访问性（focus 可见）

## Dependencies

- 无
