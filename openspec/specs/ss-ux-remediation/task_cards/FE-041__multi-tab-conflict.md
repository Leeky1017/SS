# Task Card: FE-041 Multi-tab conflict

- Priority: P2-MEDIUM
- Area: Frontend / State
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

多标签页冲突（token/状态被覆盖）无提示。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/storage.ts`
- `frontend/src/main.tsx`

## 解决方案

1. 使用 storage event 检测同 jobId 的冲突
2. 提示用户选择以哪个标签页为准

## 验收标准

- [ ] 检测到冲突时 UI 有明确提示
- [ ] 用户可安全恢复到一致状态

## Dependencies

- 无
