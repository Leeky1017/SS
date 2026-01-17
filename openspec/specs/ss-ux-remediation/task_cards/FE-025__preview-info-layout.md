# Task Card: FE-025 Preview info layout

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

预览信息行过密，信息难以扫读。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 将信息分组/分行展示
2. 弱化次要信息，突出关键变量

## 验收标准

- [ ] 关键信息一眼可见
- [ ] 窄屏下信息不拥挤且可读

## Dependencies

- 无
