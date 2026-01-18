# Task Card: FE-059 Privacy notice

- Priority: P2-MEDIUM
- Area: Frontend / Privacy
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

无隐私说明，用户无法评估数据风险。

## 技术分析

- 现状：
  - UI 缺少隐私政策/数据处理说明入口：header/主流程页面没有可点击的“隐私说明”链接或弹窗，用户无法主动查看数据如何被使用与保存。
  - 未明确告知数据处理边界：上传的数据、生成产物（artifacts）、运行日志等是否会持久化、保留多久、如何删除/撤回，在 UI 中没有说明。
  - 认证 token 会写入本地存储，但用户未被提示其含义、有效期与清除方式，造成“不透明”的数据/权限风险感知。
- 影响：用户无法评估数据风险与合规性，降低信任并可能触发合规阻断（尤其是机构用户）。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/App.tsx`
  - `frontend/src/features/step1/Step1.tsx`
  - `frontend/src/state/storage.ts`

## 解决方案

1. 增加隐私说明入口与摘要
2. 明确数据用途/保留时间/下载产物包含内容

## 验收标准

- [ ] 存在隐私说明入口
- [ ] 说明内容可读且不暴露内部实现细节

## Dependencies

- 无
