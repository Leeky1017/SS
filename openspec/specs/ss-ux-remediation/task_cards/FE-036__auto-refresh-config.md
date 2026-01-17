# Task Card: FE-036 Auto refresh config

- Priority: P3-LOW
- Area: Frontend / Status
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

自动刷新间隔硬编码，无法按场景调整。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/status/Status.tsx`

## 解决方案

1. 将刷新间隔抽为常量/配置
2. 允许根据状态动态调整频率

## 验收标准

- [ ] 刷新间隔不再散落硬编码
- [ ] 不同状态下刷新频率合理

## Dependencies

- 无
