# Task Card: BE-003 Pagination API

- Priority: P2-MEDIUM
- Area: Backend / Lists
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

无分页 API，列表数据变大后性能与可用性下降。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `src/api/admin/jobs.py`
- `src/domain/job_indexer.py`

## 解决方案

1. 为 list endpoints 增加 limit/offset（或 cursor）参数
2. 响应包含分页元信息（total/next_cursor 等）

## 验收标准

- [ ] 分页参数生效且稳定
- [ ] 前端可基于元信息实现分页 UI

## Dependencies

- 无
