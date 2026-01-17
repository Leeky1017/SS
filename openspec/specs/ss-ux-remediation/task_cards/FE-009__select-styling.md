# Task Card: FE-009 Select styling

- Priority: P2-MEDIUM
- Area: Frontend / Controls
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Select 控件浏览器差异导致样式不一致。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 统一 select 的基础样式（padding/border/arrow）
2. 确保在主流浏览器表现一致

## 验收标准

- [ ] Chrome/Safari/Firefox 下 select 样式一致（可接受范围内）
- [ ] focus/disabled 状态清晰

## Dependencies

- 无
