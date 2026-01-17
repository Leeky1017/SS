# Task Card: FE-027 File type validation

- Priority: P1-HIGH
- Area: Frontend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

文件类型仅靠扩展名，缺少更可靠校验与提示。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`

## 解决方案

1. 前端在选择文件时做基础校验（mime/扩展名）
2. 后端失败时给出清晰错误与可操作提示

## 验收标准

- [ ] 不支持的文件类型在选择时即提示
- [ ] 后端拒绝时前端显示可操作错误

## Dependencies

- 无
