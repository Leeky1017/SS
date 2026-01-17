# Task Card: FE-047 Keyboard navigation

- Priority: P1-HIGH
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

键盘导航缺失，无法无鼠标完成操作。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src`

## 解决方案

1. 为关键交互补充 tab 顺序与快捷键
2. 确保 focus 可见

## 验收标准

- [ ] 仅用键盘可完成主流程
- [ ] focus 样式清晰可见

## Dependencies

- 无
