# Task Card: FE-048 Screen reader support

- Priority: P1-HIGH
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

屏幕阅读器不支持，缺少语义与 aria 标注。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src`

## 解决方案

1. 补充语义标签与 aria 属性
2. 为动态区域提供 aria-live

## 验收标准

- [ ] 关键页面可被读屏器理解
- [ ] 无 aria 误用导致噪音

## Dependencies

- 无
