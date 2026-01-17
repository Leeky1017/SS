# Task Card: FE-045 Terminology tooltips

- Priority: P3-LOW
- Area: Frontend / UX copy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

术语无解释，用户无法理解关键概念。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 为关键术语提供 tooltip/解释
2. 术语解释进入 i18n

## 验收标准

- [ ] 关键术语有简短解释
- [ ] 解释不暴露内部实现术语

## Dependencies

- 无
