# Task Card: FE-035 Sheet selection memory

- Priority: P2-MEDIUM
- Area: Frontend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Sheet 选择不记忆，刷新后丢失选择。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/storage.ts`
- `frontend/src/features/step2/Step2.tsx`

## 解决方案

1. 将 sheet 选择持久化为 per-job snapshot
2. 刷新后自动恢复并提示

## 验收标准

- [ ] 刷新后 sheet 选择可恢复
- [ ] 确认/重置后清理该 snapshot

## Dependencies

- 无
