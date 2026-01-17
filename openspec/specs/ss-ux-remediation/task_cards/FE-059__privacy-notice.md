# Task Card: FE-059 Privacy notice

- Priority: P1-HIGH
- Area: Frontend / Privacy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无隐私说明，用户无法评估数据风险。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/App.tsx`

## 解决方案

1. 增加隐私说明入口与摘要
2. 明确数据用途/保留时间/下载产物包含内容

## 验收标准

- [ ] 存在隐私说明入口
- [ ] 说明内容可读且不暴露内部实现细节

## Dependencies

- 无
