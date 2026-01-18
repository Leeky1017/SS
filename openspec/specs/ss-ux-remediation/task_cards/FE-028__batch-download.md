# Task Card: FE-028 Batch download

- Priority: P2-MEDIUM
- Area: Frontend / Outputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无批量下载，下载多个 artifacts 需要逐个点击。

## 技术分析

- 现状：
  - Status 页的 artifacts 列表仅提供“逐行下载”按钮：每个 artifact 一次点击触发一次下载，无法多选、无法一键打包。
  - 下载实现为“逐文件 GET + blob 下载”：前端通过 `downloadArtifact(jobId, rel_path)` 单独拉取文件；当 artifacts 数量变多时，用户需要重复操作且难以确认是否漏下。
  - 缺少“批量下载”的稳定契约：前端目前没有可调用的 zip 打包端点；即使加 UI，也需要后端提供 zip 生成/下载接口与错误处理。
- 影响：高频手动点击导致体验差、易漏下载、难协作（无法一次性交付完整产物）。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/features/status/Status.tsx`
  - `frontend/src/api/client.ts`

## 解决方案

1. 支持多选 artifacts 并触发打包下载
2. 打包下载失败时给出可操作错误

## 验收标准

- [ ] 支持一键下载所选 artifacts（zip）
- [ ] 下载过程中状态明确（busy/progress）

## Dependencies

- `BE-002__zip-download-endpoint.md` (后端 zip 打包下载端点)
