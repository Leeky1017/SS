# Task Card: FE-049 Colorblind support

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

色盲区分困难（仅用颜色表达状态）。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/styles/theme.css`

## 解决方案

1. 为状态增加图标/文本
2. 调整颜色组合以可区分

## 验收标准

- [ ] 状态不只靠颜色表达
- [ ] 色盲模式下仍可辨识

## Dependencies

- 无
