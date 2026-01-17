# Task Card: FE-064 Version changelog entry

- Priority: P3-LOW
- Area: Frontend / UX
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无版本号入口，无法定位当前版本与变更。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/App.tsx`

## 解决方案

1. 在 UI 提供版本号展示
2. 链接到变更记录（指针性质）

## 验收标准

- [ ] UI 可查看版本号
- [ ] 版本号与构建产物一致

## Dependencies

- 无
