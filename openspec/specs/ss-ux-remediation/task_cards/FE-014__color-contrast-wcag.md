# Task Card: FE-014 Color contrast (WCAG)

- Priority: P1-HIGH
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

颜色对比度未验证，可能不满足可读性要求。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/theme.css`

## 解决方案

1. 对关键文本/按钮/提示色做对比度检查
2. 必要时调整 CSS 变量以满足 WCAG 基线

## 验收标准

- [ ] 关键文本与背景对比度满足 WCAG AA（或明确例外）
- [ ] 浅色/深色模式均通过检查

## Dependencies

- 无
