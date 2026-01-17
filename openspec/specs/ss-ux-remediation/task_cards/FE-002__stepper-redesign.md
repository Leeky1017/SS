# Task Card: FE-002 Stepper redesign

- Priority: P1-HIGH
- Area: Frontend / Navigation
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Stepper 不可交互且无标签，用户不知道当前步骤与可回退性。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/main.tsx`
- `frontend/src/features/step2/Step2.tsx`
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 为 Stepper 增加清晰的步骤标签与当前态
2. 允许回到已完成步骤（不丢失本地输入）

## 验收标准

- [ ] Stepper 展示步骤名称与当前位置
- [ ] 已完成步骤可点击返回且不清空已填写信息

## Dependencies

- 无
