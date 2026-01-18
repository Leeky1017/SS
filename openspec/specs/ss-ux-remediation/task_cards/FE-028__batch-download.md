# Task Card: FE-028 Batch download

- Priority: P2-MEDIUM
- Area: Frontend / Outputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无批量下载，下载多个 artifacts 需要逐个点击。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
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
