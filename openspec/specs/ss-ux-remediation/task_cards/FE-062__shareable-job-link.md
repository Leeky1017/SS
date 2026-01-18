# Task Card: FE-062 Shareable job link

- Priority: P2-MEDIUM
- Area: Frontend / UX
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无分享链接，难以协作与复现。

## 技术分析

- 现状：
  - 任务标识（`jobId`）虽已体现在 URL 路由中（`/jobs/:jobId/...`），但 UI 没有显式的“复制链接/分享”入口，用户很难意识到可以直接分享当前任务页面用于协作或复现。
  - 缺少对“可分享内容边界”的提示：需要明确链接不包含 token（token 另存于本地），并避免引导用户复制包含敏感信息的内容。
  - 分享入口应在最常用的页面（状态页/下载页）可见，且提供一键复制与成功提示。
- 影响：协作沟通成本高（需要手动解释如何获取链接/任务），也不利于向支持人员复现问题。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/features/status/Status.tsx`
  - `frontend/src/main.tsx`
  - `frontend/src/state/storage.ts`

## 解决方案

1. 提供复制当前 job 链接按钮
2. 分享时不泄露 token

## 验收标准

- [ ] 可一键复制 job 链接
- [ ] 分享链接不包含敏感 token

## Dependencies

- 无
