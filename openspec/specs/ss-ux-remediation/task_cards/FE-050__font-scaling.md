# Task Card: FE-050 Font scaling

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

字体不可缩放，影响可读性。

## 技术分析

- 现状：
  - 字体与布局大量使用固定 `px`（例如 `body` 字号、header 高度、各类 padding/字号），未以 `rem/em` 为主；当用户调整浏览器默认字号/系统字体缩放时，页面不一定能按比例放大。
  - 存在固定高度组件（如 `.btn` height 固定），在字体放大后可能出现文本拥挤、截断或按钮溢出。
- 影响：低视力用户依赖字体缩放提高可读性时，页面可用性下降（读不清/点不到/布局崩坏）。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/theme.css`
  - `frontend/src/styles/layout.css`
  - `frontend/src/styles/components.css`

## 解决方案

1. 使用相对单位并测试浏览器缩放
2. 避免固定 px 导致布局崩

## 验收标准

- [ ] 浏览器缩放后布局仍可用
- [ ] 文本不会被截断隐藏

## Dependencies

- 无
