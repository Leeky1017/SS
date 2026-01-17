# Task Card: FE-039 Browser back button behavior

- Priority: P1-HIGH
- Area: Frontend / Navigation
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

浏览器后退行为错乱，容易回到不一致状态。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/main.tsx`

## 解决方案

1. 明确 replace vs push 的使用策略
2. 关键跳转使用 replace 避免返回到中间态

## 验收标准

- [ ] 后退不会回到“不可用/中间态”页面
- [ ] 后退行为与 stepper/按钮导航一致

## Dependencies

- 无
