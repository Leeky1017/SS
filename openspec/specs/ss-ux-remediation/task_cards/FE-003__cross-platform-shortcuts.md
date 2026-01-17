# Task Card: FE-003 Cross-platform shortcuts

- Priority: P2-MEDIUM
- Area: Frontend / i18n
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

快捷键提示仅支持 macOS（⌘），Windows/Linux 用户困惑。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step1/Step1.tsx`

## 解决方案

1. 根据平台渲染快捷键提示（mac=⌘，win/linux=Ctrl）
2. 在提示文案中保持与 i18n 一致

## 验收标准

- [ ] mac 显示 ⌘，win/linux 显示 Ctrl
- [ ] 无硬编码平台符号散落在组件中

## Dependencies

- 无
