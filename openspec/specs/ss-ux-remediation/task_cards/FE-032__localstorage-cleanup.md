# Task Card: FE-032 localStorage cleanup

- Priority: P2-MEDIUM
- Area: Frontend / State
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

localStorage 残留未清理，导致跨任务污染与隐私风险。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/storage.ts`

## 解决方案

1. 为 per-job snapshots 提供统一清理函数
2. 在 reset/unauthorized/完成后按策略清理

## 验收标准

- [ ] 完成/重置后相关 key 被清理
- [ ] 不会误删其他 job 的数据

## Dependencies

- 无
