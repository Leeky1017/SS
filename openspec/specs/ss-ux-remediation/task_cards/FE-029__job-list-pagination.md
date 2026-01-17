# Task Card: FE-029 Job list pagination

- Priority: P2-MEDIUM
- Area: Frontend / Admin
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

任务列表无分页，列表变长后性能/可用性下降。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/admin/pages/AdminJobsPage.tsx`

## 解决方案

1. 在列表 UI 增加分页控件
2. 后端支持分页查询

## 验收标准

- [ ] 列表支持分页（上一页/下一页/页大小）
- [ ] 分页与筛选联动正常

## Dependencies

- 依赖后端 BE-003（分页 API）
