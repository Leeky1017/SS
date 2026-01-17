# Task Card: FE-063 Dynamic page title

- Priority: P2-MEDIUM
- Area: Frontend / Navigation
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

页面标题不变，多标签页难区分。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/main.tsx`

## 解决方案

1. 根据路由更新 document.title
2. 标题包含 step 名称与 jobId 片段

## 验收标准

- [ ] 不同步骤页面标题不同
- [ ] 标题包含可识别的任务引用

## Dependencies

- 无
