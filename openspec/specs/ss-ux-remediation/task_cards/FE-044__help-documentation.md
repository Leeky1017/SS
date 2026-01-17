# Task Card: FE-044 Help documentation entry

- Priority: P3-LOW
- Area: Frontend / UX copy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无帮助文档入口，用户遇到问题无处查。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/App.tsx`

## 解决方案

1. 在主导航/页脚增加帮助入口
2. 帮助内容保持指针性质，不在 docs/ 形成第二体系

## 验收标准

- [ ] 页面有帮助入口
- [ ] 帮助内容为指针/FAQ，不与 OpenSpec 冲突

## Dependencies

- 无
