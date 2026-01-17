# Task Card: FE-060 Secure token storage

- Priority: P1-HIGH
- Area: Frontend / Security
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Token 存储不安全/不透明，用户无法控制。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/storage.ts`

## 解决方案

1. 最小化 token 暴露面（仅必要时读取）
2. 提供清除/过期策略与用户提示

## 验收标准

- [ ] token 可被一键清除
- [ ] 401/403 时自动清除并引导重新兑换

## Dependencies

- 无
