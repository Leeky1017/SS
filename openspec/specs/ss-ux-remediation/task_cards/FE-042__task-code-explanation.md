# Task Card: FE-042 Task code explanation

- Priority: P2-MEDIUM
- Area: Frontend / UX copy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

“任务验证码”概念不明，新用户不知道是什么、从哪里来。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step1/Step1.tsx`

## 解决方案

1. 在 Step1 增加一句话解释与示例
2. 开发模式下说明如何获取/是否可空

## 验收标准

- [ ] 页面有清晰解释与示例
- [ ] 不引入内部术语（API/JSON 等）

## Dependencies

- 无
