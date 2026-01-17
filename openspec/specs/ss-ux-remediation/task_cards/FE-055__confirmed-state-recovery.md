# Task Card: FE-055 Confirmed state recovery

- Priority: P2-MEDIUM
- Area: Frontend / Recovery
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

确认后无法撤回/恢复，用户无法应对误确认。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step3/Step3.tsx`
- `frontend/src/features/status/Status.tsx`

## 解决方案

1. 明确 confirmed 后可做的恢复路径（查看/下载/重新开始）
2. 避免让用户“卡死”在只读态

## 验收标准

- [ ] confirmed 后有清晰可选路径
- [ ] 不会误导用户以为还能修改已确认内容

## Dependencies

- 无
