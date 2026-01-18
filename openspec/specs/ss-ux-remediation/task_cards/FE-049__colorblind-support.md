# Task Card: FE-049 Colorblind support

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

色盲区分困难（仅用颜色表达状态）。

## 技术分析

- 现状：
  - 成功/错误/完成等状态主要依赖颜色表达：例如 stepper 的完成态使用 `--success`，错误面板使用红色边框/底色；对色觉缺陷用户不友好。
  - 状态缺少一致的冗余表达（图标/文本标签）：即使颜色不可区分，也应能通过图标或明确文案区分“成功/失败/进行中”。
- 影响：在色盲模式、低对比显示器或强光环境下，用户更容易误判状态并做出错误操作。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/theme.css`
  - `frontend/src/styles/components.css`
  - `frontend/src/components/ErrorPanel.tsx`
  - `frontend/src/features/status/Status.tsx`

## 解决方案

1. 为状态增加图标/文本
2. 调整颜色组合以可区分

## 验收标准

- [ ] 状态不只靠颜色表达
- [ ] 色盲模式下仍可辨识

## Dependencies

- 无
