# Task Card: BE-001 Chunked upload

- Priority: P2-MEDIUM
- Area: Backend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

不支持分块上传进度（需要可续传/可展示进度的上传能力）。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `src/api/inputs_upload_sessions.py`
- `src/domain/upload_sessions_service.py`

## 解决方案

1. 梳理并完善上传会话/分块接口对外契约（必要时从 internal 变为稳定接口）
2. 为前端提供可计算的进度信息（已完成分块/总分块）

## 验收标准

- [ ] 存在稳定的分块上传 API 契约
- [ ] 前端可展示上传进度并支持失败重试

## Dependencies

- 无
