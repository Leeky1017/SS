# Task Card: FE-052 Touch device UX

- Priority: P2-MEDIUM
- Area: Frontend / Layout
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

触摸设备体验差（目标小/滚动难）。

## 技术分析

- 现状：
  - 触摸目标偏小：基础按钮高度为 38px，部分关键按钮（如下载）还使用更小高度，低于常见触控可用性下限（≥44px）。
  - 上传交互对触摸不友好：上传区主要依赖 `dragover/drop`，触摸设备通常无法触发拖拽上传；虽然提供“选择文件”，但实现为 `label` 伪装按钮，禁用态与可达性容易不一致。
  - 滚动体验风险：大量使用 `overflow: auto` 的容器（表格/列表），在移动端容易出现滚动冲突或误触（尤其与 sticky 列叠加时）。
- 影响：移动端/平板难以稳定完成上传、预览、确认与下载等关键操作，误触概率上升。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/components.css`
  - `frontend/src/features/step2/Step2UploadPanel.tsx`
  - `frontend/src/features/status/Status.tsx`

## 解决方案

1. 调整触摸目标尺寸与间距
2. 优化滚动区域与遮挡

## 验收标准

- [ ] 触摸设备可完成主流程
- [ ] 滚动/点击不易误触

## Dependencies

- 无
