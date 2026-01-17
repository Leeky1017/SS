# Task Card: FE-022 Cell content expand

- Priority: P3-LOW
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

单元格截断无展开，无法查看完整值。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 为长内容提供展开/复制入口（popover）
2. 保持表格不被撑爆

## 验收标准

- [ ] 截断单元格可展开查看完整值
- [ ] 用户可复制完整内容

## Dependencies

- 无
