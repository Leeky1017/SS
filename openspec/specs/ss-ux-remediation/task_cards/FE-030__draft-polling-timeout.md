# Task Card: FE-030 Draft polling timeout

- Priority: P1-HIGH
- Area: Frontend / Loading
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

草稿轮询无超时，可能无限等待。

## 技术分析

- 现状：
  - Step3 对 draft preview 使用“pending → setTimeout → 再请求”的轮询机制，但前端没有 max retries / 总时长上限；只要后端持续返回 pending，页面会无限轮询。
  - pending UI 信息不足：`pendingMessage()` 当前固定返回 `null`，用户只能看到“等待/倒计时”，缺少“已等待多久/还会等多久/下一步建议”。
  - 轮询退出路径不清晰：缺少“停止轮询/手动重试/返回上一步”的明确按钮与可操作错误提示。
- 影响：在后端卡住、任务异常或网络抖动时，用户可能无限等待，难以判断是“正常生成中”还是“已经失败/卡死”。
- 代码定位锚点（仅用于快速开始；以实际实现为准）：
  - `frontend/src/features/step3/Step3.tsx`
  - `frontend/src/api/client.ts`

## 解决方案

1. 为草稿/预览轮询增加超时或 max retries
2. 到达上限后提供重试/反馈入口

## 验收标准

- [ ] 轮询有明确上限与倒计时/提示
- [ ] 到达上限后不再静默等待，提供下一步按钮

## Dependencies

- `BE-004__draft-max-retry.md` (后端草稿生成 max retries / 上限)
