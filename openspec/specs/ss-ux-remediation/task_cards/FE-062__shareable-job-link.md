# Task Card: FE-062 Shareable job link

- Priority: P3-LOW
- Area: Frontend / UX
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无分享链接，难以协作与复现。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/status/Status.tsx`

## 解决方案

1. 提供复制当前 job 链接按钮
2. 分享时不泄露 token

## 验收标准

- [ ] 可一键复制 job 链接
- [ ] 分享链接不包含敏感 token

## Dependencies

- 无
