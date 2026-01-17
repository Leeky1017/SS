# Task Card: FE-016 i18n completion

- Priority: P2-MEDIUM
- Area: Frontend / i18n
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

i18n 不完整，存在硬编码文案。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src`

## 解决方案

1. 梳理所有用户可见文本并纳入 i18n
2. 保证用户端与管理端一致

## 验收标准

- [ ] 无用户可见硬编码中文/英文散落
- [ ] 文案可统一替换与维护

## Dependencies

- 无
