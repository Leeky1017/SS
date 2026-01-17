# Task Card: FE-034 Retry exponential backoff

- Priority: P2-MEDIUM
- Area: Frontend / Reliability
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

重试无指数退避，可能造成过载或体验抖动。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/api/client.ts`

## 解决方案

1. 为可重试错误（网络/5xx/202 pending）实现指数退避
2. 提供取消/立即重试入口

## 验收标准

- [ ] 重试间隔按指数退避增长且有上限
- [ ] 用户能看到下一次重试时间并可手动重试

## Dependencies

- 无
