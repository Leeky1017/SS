# Task Card: FE-004 Error panel enhancement

- Priority: P1-HIGH
- Area: Frontend / Errors
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

错误面板无复制、无折叠，无法快速提取 request id 或关键信息。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/components/ErrorPanel.tsx`

## 解决方案

1. 在错误面板中提供一键复制 request id/错误代号
2. 将技术细节折叠展示，保留可操作按钮

## 验收标准

- [ ] 错误面板支持复制 request id
- [ ] 技术细节默认折叠且可展开
- [ ] 错误面板提供明确的下一步按钮（重试/重新兑换/回到开始）

## Dependencies

- 无
