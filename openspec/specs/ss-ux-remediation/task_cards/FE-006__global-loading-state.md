# Task Card: FE-006 Global loading state

- Priority: P1-HIGH
- Area: Frontend / Loading
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

全局无 Loading 指示器，长请求期间用户无感知。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/api/client.ts`
- `frontend/src/main.tsx`

## 解决方案

1. 引入全局 busy 指示器（请求>300ms 时显示）
2. 确保 busy 状态在成功/失败/取消时正确清除

## 验收标准

- [ ] 长请求时出现全局 busy 指示器
- [ ] 请求结束后 busy 指示器消失（无卡死）

## Dependencies

- 无
