# Task Card: FE-064 Version changelog entry

- Priority: P2-MEDIUM
- Area: Frontend / UX
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无版本号入口，无法定位当前版本与变更。

## 技术分析

- 现状：
  - UI 未展示当前版本号：出现问题时用户/支持人员无法确认“我用的是哪个版本”，也无法对照变更记录定位是否为已修复问题。
  - 缺少更新日志入口：即使后续提供了 changelog 文档（指针性质），也没有从 UI 可达的入口。
  - 版本信息需要可追溯且与构建产物一致（通常来自构建时注入或 `package.json`），目前没有相关展示路径。
- 影响：问题定位与回归验证成本上升（无法快速判断是否为版本差异导致）。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/App.tsx`
  - `frontend/src/main.tsx`
  - `frontend/package.json`

## 解决方案

1. 在 UI 提供版本号展示
2. 链接到变更记录（指针性质）

## 验收标准

- [ ] UI 可查看版本号
- [ ] 版本号与构建产物一致

## Dependencies

- 无
