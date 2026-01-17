# Task Card: FE-012 Time localization

- Priority: P2-MEDIUM
- Area: Frontend / i18n
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

时间未本地化，ISO/默认格式混用不友好。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/status/Status.tsx`
- `frontend/src/features/admin/pages/AdminJobsPage.tsx`

## 解决方案

1. 统一时间格式为中文可读格式
2. 明确时区策略（展示本地时间或固定时区）

## 验收标准

- [ ] 所有用户可见时间字段展示为中文可读格式
- [ ] 同类字段格式一致（created/updated 等）

## Dependencies

- 无
