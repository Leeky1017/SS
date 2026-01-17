# Task Card: FE-057 Skeleton loading

- Priority: P2-MEDIUM
- Area: Frontend / Loading
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无骨架屏，等待期间界面跳变大。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 为关键区域增加 skeleton
2. 与全局 loading 协同

## 验收标准

- [ ] 加载期间有 skeleton 占位
- [ ] 数据到达后平滑替换

## Dependencies

- 无
