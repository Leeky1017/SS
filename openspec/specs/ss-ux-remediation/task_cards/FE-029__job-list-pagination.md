# Task Card: FE-029 Job list pagination

- Priority: P2-MEDIUM
- Area: Frontend / Admin
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

任务列表无分页，列表变长后性能/可用性下降。

## 技术分析

- 现状：
  - Admin 任务列表请求没有分页参数：`listJobs` 只支持 `tenant_id/status` 过滤，不支持 `limit/offset` 或 `cursor`，导致列表随数据增长会一次性返回大量记录。
  - 前端一次性渲染整表：页面把 `jobs` 全量塞进 state 并渲染 `<table>`，在任务量大时会明显卡顿（渲染/滚动/交互），也不利于快速定位目标任务。
- 影响：任务量上升后性能与可用性下降（加载慢、滚动卡、难以快速找到目标记录），并增加后端单次响应压力。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/features/admin/pages/AdminJobsPage.tsx`
  - `frontend/src/features/admin/adminApi.ts`

## 解决方案

1. 在列表 UI 增加分页控件
2. 后端支持分页查询

## 验收标准

- [ ] 列表支持分页（上一页/下一页/页大小）
- [ ] 分页与筛选联动正常

## Dependencies

- `BE-003__pagination-api.md` (后端分页查询 API)
