# Task Card: FE-050 Font scaling

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

字体不可缩放，影响可读性。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/theme.css`

## 解决方案

1. 使用相对单位并测试浏览器缩放
2. 避免固定 px 导致布局崩

## 验收标准

- [ ] 浏览器缩放后布局仍可用
- [ ] 文本不会被截断隐藏

## Dependencies

- 无
