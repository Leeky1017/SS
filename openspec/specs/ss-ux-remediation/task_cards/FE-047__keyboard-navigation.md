# Task Card: FE-047 Keyboard navigation

- Priority: P2-MEDIUM
- Area: Frontend / Accessibility
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

键盘导航缺失，无法无鼠标完成操作。

## 技术分析

- 现状：
  - Tab 顺序未针对“主流程”优化：页面缺少 “跳到主内容（skip link）”，键盘用户需要先穿过 header 才能到达核心表单/按钮。
  - Focus 样式缺失：全局禁用 `outline`，且 `.btn`/`input`/`select` 未提供清晰的 `:focus-visible` 样式，导致无法判断当前焦点位置。
  - 交互元素可达性不一致：存在用 `label` 伪装按钮触发文件选择等模式，默认不一定可聚焦，Enter/Space 行为也容易和预期不一致。
  - 弹窗缺少焦点管理：打开时未自动聚焦首个可交互控件，关闭时未回到触发点，易造成“迷失焦点”。
- 影响：无法仅用键盘稳定完成“领取 → 上传 → 预览 → 确认 → 状态/下载”，且误操作概率上升。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/theme.css`
  - `frontend/src/styles/components.css`
  - `frontend/src/App.tsx`
  - `frontend/src/features/step2/Step2UploadPanel.tsx`
  - `frontend/src/features/step3/panelsConfirm.tsx`

## 解决方案

1. 为关键交互补充 tab 顺序与快捷键
2. 确保 focus 可见

## 验收标准

- [ ] 仅用键盘可完成主流程
- [ ] focus 样式清晰可见

## Dependencies

- 无
