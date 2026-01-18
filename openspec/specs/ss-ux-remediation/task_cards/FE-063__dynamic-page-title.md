# Task Card: FE-063 Dynamic page title

- Priority: P2-MEDIUM
- Area: Frontend / Navigation
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

页面标题不变，多标签页难区分。

## 技术分析

- 现状：
  - 应用没有根据路由/步骤动态设置 `document.title`；多标签页同时打开时，所有页标题相同，用户无法区分“上传/预览/状态”。
  - 页面标题未包含任务识别信息（例如 `jobId` 片段），在协作沟通与回到正确标签页时成本更高。
- 影响：多任务并行时容易点错标签页并误操作（例如在错误任务上重新开始/下载）。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/main.tsx`
  - `frontend/src/App.tsx`
  - `frontend/src/features/step1/Step1.tsx`
  - `frontend/src/features/step2/Step2.tsx`
  - `frontend/src/features/step3/Step3.tsx`
  - `frontend/src/features/status/Status.tsx`

## 解决方案

1. 根据路由更新 document.title
2. 标题包含 step 名称与 jobId 片段

## 验收标准

- [ ] 不同步骤页面标题不同
- [ ] 标题包含可识别的任务引用

## Dependencies

- 无
