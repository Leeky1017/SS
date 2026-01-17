# Task Card: FE-015 Step navigation

- Priority: P1-HIGH
- Area: Frontend / Navigation
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无返回上一步入口，用户只能重来。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 在 Step2/Step3 提供“返回上一步”按钮
2. 返回时保留已填写内容（local draft）

## 验收标准

- [ ] 用户可从 Step3 返回 Step2（不重新兑换）
- [ ] 返回不丢失 Step3 本地填写（best-effort）

## Dependencies

- 无
