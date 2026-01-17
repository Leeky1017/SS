# Task Card: FE-017 Dark mode system sync

- Priority: P2-MEDIUM
- Area: Frontend / Theme
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Dark Mode 不跟随系统，默认策略不一致。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/theme.ts`
- `frontend/src/styles/theme.css`

## 解决方案

1. 默认跟随 prefers-color-scheme
2. 允许用户手动覆盖并持久化

## 验收标准

- [ ] 默认主题与系统一致
- [ ] 用户切换主题后可持久化覆盖

## Dependencies

- 无
