# Task Card: FE-030 Draft polling timeout

- Priority: P1-HIGH
- Area: Frontend / Loading
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

草稿轮询无超时，可能无限等待。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/Step3.tsx`
- `frontend/src/api/client.ts`

## 解决方案

1. 为草稿/预览轮询增加超时或 max retries
2. 到达上限后提供重试/反馈入口

## 验收标准

- [ ] 轮询有明确上限与倒计时/提示
- [ ] 到达上限后不再静默等待，提供下一步按钮

## Dependencies

- 无
