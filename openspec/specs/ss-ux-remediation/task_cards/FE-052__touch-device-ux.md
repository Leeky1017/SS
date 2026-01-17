# Task Card: FE-052 Touch device UX

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

触摸设备体验差（目标小/滚动难）。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/components.css`

## 解决方案

1. 调整触摸目标尺寸与间距
2. 优化滚动区域与遮挡

## 验收标准

- [ ] 触摸设备可完成主流程
- [ ] 滚动/点击不易误触

## Dependencies

- 无
