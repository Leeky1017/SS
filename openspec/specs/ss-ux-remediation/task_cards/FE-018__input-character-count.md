# Task Card: FE-018 Input character count

- Priority: P3-LOW
- Area: Frontend / Forms
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

输入框无字符计数，用户不知道限制与当前长度。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step1/Step1.tsx`

## 解决方案

1. 为关键 textarea/input 增加字符计数与限制提示
2. 限制策略进入 i18n

## 验收标准

- [ ] 输入框显示当前字数/上限
- [ ] 超过上限有明确提示且不丢内容

## Dependencies

- 无
