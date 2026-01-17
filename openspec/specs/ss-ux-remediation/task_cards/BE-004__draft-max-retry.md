# Task Card: BE-004 Draft polling max_retry

- Priority: P1-HIGH
- Area: Backend / Draft
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

草稿轮询无 max_retry，可能导致无限 pending。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `src/api/draft.py`
- `src/domain/draft_service.py`

## 解决方案

1. 在 pending 响应中返回可执行的上限信息（retry_until/max_retries）
2. 到达上限后返回结构化错误并给出 next_actions

## 验收标准

- [ ] pending 轮询有明确上限语义
- [ ] 到达上限后不再无限 pending，返回可操作错误

## Dependencies

- 无
