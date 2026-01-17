# Task Card: FE-046 Step dependency clarity

- Priority: P2-MEDIUM
- Area: Frontend / UX copy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Step 依赖关系不清，用户不知道为何被阻塞。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 当缺少前置条件时显示原因与解决路径
2. 避免按钮灰掉但不解释

## 验收标准

- [ ] 被阻塞时 UI 显示原因与解决按钮
- [ ] 用户能理解下一步如何达成

## Dependencies

- 无
