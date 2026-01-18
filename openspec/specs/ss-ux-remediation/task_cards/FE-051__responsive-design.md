# Task Card: FE-051 Responsive design

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无响应式设计，窄屏体验差。

## 技术分析

- 现状：
  - 样式缺少 `@media` 断点：header 使用三列 grid + 固定 padding，窄屏下容易挤压导致溢出或换行错位。
  - 主内容区采用固定 padding 与桌面宽度假设（例如 `main` 的 padding/max-width），在移动端会导致可视区域浪费或内容拥挤。
  - 表格容器与 sticky 列（`overflow: auto` + `position: sticky`）在小屏下更依赖横向滚动，若无断点优化会出现“看不全/点不到”的问题。
- 影响：≤768px 的窄屏设备上主流程布局崩坏，影响上传、预览与状态下载等关键操作。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/layout.css`
  - `frontend/src/styles/components.css`
  - `frontend/src/features/step2/Step2Panels.tsx`
  - `frontend/src/features/step3/panelsBase.tsx`
  - `frontend/src/features/status/Status.tsx`

## 解决方案

1. 为关键断点添加布局调整
2. 保证触摸目标大小下限

## 验收标准

- [ ] ≤768px 宽度下不崩坏
- [ ] 触摸目标 ≥ 44px

## Dependencies

- 无
