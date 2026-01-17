# Task Card: FE-040 Offline detection

- Priority: P2-MEDIUM
- Area: Frontend / Reliability
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

网络断开无提示，用户误以为系统卡死。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/components/ErrorPanel.tsx`

## 解决方案

1. 监听 online/offline 并提示
2. 离线时暂停轮询并提供重试

## 验收标准

- [ ] 断网时出现明确离线提示
- [ ] 恢复网络后可一键重试/继续

## Dependencies

- 无
