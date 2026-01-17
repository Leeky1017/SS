# Task Card: FE-005 File upload UX

- Priority: P1-HIGH
- Area: Frontend / Inputs
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

文件上传区交互不明确（状态/可上传内容/进度）。

## 技术分析

- 影响：用户对系统状态（正在加载/已完成/失败）缺乏可感知反馈，或在关键交互上产生误操作/困惑。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
- `frontend/src/features/step2/Step2.tsx`

## 解决方案

1. 明确上传区域的状态（未选择/上传中/成功/失败）
2. 展示已选择文件列表与角色（主/辅）

## 验收标准

- [ ] 上传区对“可拖拽/可点击选择”有明确提示
- [ ] 上传中有进度或明确忙碌态
- [ ] 上传失败显示可操作错误与重试

## Dependencies

- 无
