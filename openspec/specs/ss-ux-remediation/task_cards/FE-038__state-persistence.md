# Task Card: FE-038 State persistence

- Priority: P1-HIGH
- Area: Frontend / State
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

Step3 的 `variableCorrections` 与 `answers` 未持久化，刷新页面会丢失已填写内容，造成重复劳动与误操作风险。

## 技术分析

- 现状：
  - `frontend/src/state/storage.ts` 已集中管理 per-job snapshot（inputs upload/preview、draft preview、confirm lock），但未包含 Step3 的表单草稿。
  - Step3 是高投入页面：用户在此进行变量修正、补全问题、确认输出等；刷新/过期/断网后丢失输入会直接破坏 UX loop。
- 代码定位锚点：
  - `frontend/src/state/storage.ts`
  - `frontend/src/features/step3/Step3.tsx`

## 解决方案

1. 扩展 `frontend/src/state/storage.ts`，新增明确 API：
   - `saveStep3FormState(jobId, { variableCorrections, answers })`
   - `loadStep3FormState(jobId) -> { variableCorrections, answers } | null`
   - `clearStep3FormState(jobId)`（在 confirm/reset/unauthorized 时调用）
2. 在 Step3 内实现“自动保存 + 自动恢复”：
   - 用户每次修改后（去抖动可选）立即保存到 localStorage。
   - 页面加载时读取并恢复到本地 state，并用轻提示告知“已从本地草稿恢复”。
3. 清理策略：
   - confirm 成功后清理（避免旧草稿污染锁定态）。
   - reset/redeem-again/401/403 时清理（与 `clearAuthToken` 一致）。

## 验收标准

- [ ] 刷新后 Step3 表单内容保留（best-effort）
- [ ] 页面加载可自动恢复且提示来源（本地草稿）
- [ ] 确认成功后清除持久化数据（不污染后续页面/任务）

## Dependencies

- 无
