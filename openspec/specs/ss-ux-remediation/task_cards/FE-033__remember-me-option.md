# Task Card: FE-033 Remember-me option

- Priority: P3-LOW
- Area: Frontend / Auth
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无“记住我”选项，用户无法控制 token 持久化策略。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/state/storage.ts`
- `frontend/src/features/step1/Step1.tsx`

## 解决方案

1. 提供“记住我”开关决定 token 保存时长/范围
2. 明确说明风险

## 验收标准

- [ ] 用户可选择是否持久化 token
- [ ] 关闭记住我时关闭浏览器后不保留 token

## Dependencies

- 无
