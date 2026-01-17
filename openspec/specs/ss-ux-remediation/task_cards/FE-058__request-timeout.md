# Task Card: FE-058 Request timeout

- Priority: P1-HIGH
- Area: Frontend / Reliability
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

请求无超时，可能无限挂起。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/api/client.ts`

## 解决方案

1. 为 fetch 增加超时控制（AbortController）
2. 超时时展示可操作错误（重试）

## 验收标准

- [ ] 请求超过阈值会超时返回错误
- [ ] 超时错误可重试且不丢关键状态

## Dependencies

- 无
