# Task Card: FE-021 Filename tooltip

- Priority: P3-LOW
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

文件名截断无 tooltip，无法查看完整名称。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 对 ellipsis 截断文本提供 tooltip/title
2. 统一截断规则

## 验收标准

- [ ] 截断文本悬停可查看完整内容
- [ ] 不影响键盘与读屏可访问性

## Dependencies

- 无
