# Task Card: FE-026 Upload progress

- Priority: P1-HIGH
- Area: Frontend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

上传无进度，用户不知道是否在进行。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`

## 解决方案

1. 前端展示上传进度（按文件/总体）
2. 无法提供进度时显示明确 busy 状态与提示

## 验收标准

- [ ] 上传期间有可感知进度或明确 busy 状态
- [ ] 上传完成/失败有明确反馈

## Dependencies

- 无
