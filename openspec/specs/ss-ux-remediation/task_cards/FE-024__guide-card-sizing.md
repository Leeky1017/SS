# Task Card: FE-024 Guide card sizing

- Priority: P3-LOW
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

方法引导卡片高度不一，影响扫读与一致性。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step1/Step1.tsx`
- `frontend/src/styles/components.css`

## 解决方案

1. 统一卡片最小高度与排版
2. 保证内容密度一致

## 验收标准

- [ ] 同一行卡片高度一致
- [ ] 主要信息不被折叠/遮挡

## Dependencies

- 无
