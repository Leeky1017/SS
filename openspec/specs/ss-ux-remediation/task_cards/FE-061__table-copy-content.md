# Task Card: FE-061 Table copy content

- Priority: P2-MEDIUM
- Area: Frontend / Tables
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

表格内容不可复制，影响变量核对与沟通。

## 技术分析

- 现状：
  - 表格容器使用 `overflow: auto`，并在表头/首列使用 `position: sticky`；在部分浏览器/触控环境中，这类组合容易导致“拖动即滚动”，文本选择体验很差甚至无法完成复制。
  - 预览表格存在截断展示（`clipCell`），用户即使复制也可能拿不到完整内容；需要明确“可复制完整值”的交互（例如点击展开/复制按钮）。
  - 当前样式未明确保证 `user-select: text`，并缺少“复制成功/失败”的反馈。
- 影响：用户无法方便地复制列名/单元格内容进行核对、沟通或外部记录，增加反复截图/手抄成本。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/styles/components.css`
  - `frontend/src/features/step2/Step2Panels.tsx`
  - `frontend/src/features/step3/panelsBase.tsx`
  - `frontend/src/features/status/Status.tsx`

## 解决方案

1. 允许选择/复制表格文本
2. 避免 CSS 禁用选择导致不可复制

## 验收标准

- [ ] 用户可复制列名与单元格内容
- [ ] 复制不破坏表格交互

## Dependencies

- 无
