# UX Task Card: Admin UX Basics

## Covers

- 29, 33
- 12

## Problem (plain language)

管理端是运维入口，也需要基本可用性：
- 任务列表无分页/搜索，任务多了会卡。
- 登录 token 存 localStorage，缺少过期管理与“记住我”控制。
- 时间显示直接 ISO，难读。

## Acceptance

- [ ] 任务列表支持分页（或无限滚动）与搜索（至少按 job_id / 时间 / 状态）
- [ ] token 存储与过期策略清晰（并提供“记住我”开关或等价机制）
- [ ] Admin 时间显示统一为中文可读格式

## Dependencies

- 部分能力可能需要后端提供分页/筛选 API；若缺失必须在卡内明确新增契约。

