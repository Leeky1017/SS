# Task Card: FE-001 Navigation feedback

- Priority: P1-HIGH
- Area: Frontend / Interaction
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Tab 切换无 loading 反馈。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/api/client.ts`
- `frontend/src/features/step1/Step1.tsx`

## 解决方案

1. 为 Tab 切换加入明确的 loading/transition 反馈
2. 避免“静默切换”导致的误操作

## 验收标准

- [ ] Tab 切换时有即时视觉反馈（active + loading/transition cue）
- [ ] 切换过程中主操作按钮状态可预期（禁用/可点击）

## Dependencies

- 无
