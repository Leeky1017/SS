# Task Card: FE-031 View locked history

- Priority: P2-MEDIUM
- Area: Frontend / Recovery
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

锁定后无法查看历史，用户无法复核已确认内容。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 锁定态提供“查看已确认内容/历史”入口
2. 明确哪些内容不可再改，哪些可下载/查看

## 验收标准

- [ ] 锁定态可查看确认时的关键内容
- [ ] 用户理解为何不可编辑

## Dependencies

- 无
