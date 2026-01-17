# Task Card: FE-010 Button disabled state

- Priority: P2-MEDIUM
- Area: Frontend / Controls
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

按钮禁用状态不明显，用户难以判断可点击性。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 为 disabled 按钮提供更明确的样式（不仅是 opacity）
2. hover/focus 与 disabled 组合行为一致

## 验收标准

- [ ] disabled 按钮一眼可见不可点
- [ ] disabled 时 hover 不呈现“可点击”反馈

## Dependencies

- 无
