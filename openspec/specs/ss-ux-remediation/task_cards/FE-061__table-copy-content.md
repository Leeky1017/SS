# Task Card: FE-061 Table copy content

- Priority: P2-MEDIUM
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

表格内容不可复制，影响变量核对与沟通。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 允许选择/复制表格文本
2. 避免 CSS 禁用选择导致不可复制

## 验收标准

- [ ] 用户可复制列名与单元格内容
- [ ] 复制不破坏表格交互

## Dependencies

- 无
