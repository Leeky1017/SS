# Task Card: FE-054 Dangerous action confirm

- Priority: P1-HIGH
- Area: Frontend / Safety
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

危险操作无确认，容易误点导致数据丢失。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step1/Step1.tsx`
- `frontend/src/state/storage.ts`

## 解决方案

1. 为 reset/redeem-again 等操作增加二次确认
2. 说明会清除哪些本地数据

## 验收标准

- [ ] 危险操作必须确认
- [ ] 确认对话框说明数据影响

## Dependencies

- 无
