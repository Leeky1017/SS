# Task Card: FE-008 Modal keyboard support

- Priority: P1-HIGH
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Modal 无键盘支持（Escape 关闭/焦点管理）。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/panelsConfirm.tsx`
- `frontend/src/styles/components.css`

## 解决方案

1. 为 modal 增加 Escape 关闭
2. 实现基本 focus trap 与初始焦点
3. 补充 aria 属性与可聚焦元素顺序

## 验收标准

- [ ] Escape 可关闭 modal
- [ ] Tab 键在 modal 内循环
- [ ] 读屏语义（role/dialog, aria-modal）完整且不误导

## Dependencies

- 无
