# Task Card: FE-053 Undo mechanism

- Priority: P2-MEDIUM
- Area: Frontend / Recovery
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

操作无撤销，误操作代价高。

## 技术分析

- 现状：
  - 变量修正直接写入 `variableCorrections` state，没有“上一步”历史栈；任何误点都只能手动改回或逐项重选。
  - “清除修正/清空”属于一次性全清操作，不等价于撤销上一步（Undo last action），且缺少撤销提示与可恢复路径。
  - 在确认锁定后（confirmed lock）不可逆，用户对误操作的心理成本更高。
- 影响：误操作代价高，用户需要重复劳动修复输入，降低效率与信任感。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/features/step3/Step3.tsx`
  - `frontend/src/features/step3/panelsConfirm.tsx`

## 解决方案

1. 为可撤销的本地操作提供撤销
2. 不可撤销操作提供恢复路径

## 验收标准

- [ ] 关键本地操作可撤销
- [ ] 不可撤销操作有明确提示

## Dependencies

- 无
