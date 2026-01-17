# Task Card: FE-043 Actionable errors

- Priority: P1-HIGH
- Area: Frontend / Errors
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

错误信息不可操作，只显示红字无法指导下一步。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/utils/errorCodes.ts`
- `frontend/src/components/ErrorPanel.tsx`

## 解决方案

1. 将后端 error_code 映射为用户错误代号与行动指引
2. 对已知错误提供具体操作按钮

## 验收标准

- [ ] 出现错误时提供可执行的下一步按钮
- [ ] 用户看到错误代号 EXXXX + 友好解释

## Dependencies

- 无
