# Task Card: FE-056 Large file handling

- Priority: P2-MEDIUM
- Area: Frontend / Performance
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

大文件处理性能差，可能卡死或无响应。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`

## 解决方案

1. 上传前提示大文件策略（分块/限制）
2. 必要时引导使用分块上传

## 验收标准

- [ ] 大文件上传/预览有明确策略提示
- [ ] 不会因为大文件导致页面无响应

## Dependencies

- 无
