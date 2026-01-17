# Task Card: FE-037 Session expiry detection

- Priority: P1-HIGH
- Area: Frontend / Auth
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/ux-patterns.md`
  - `openspec/specs/ss-ux-remediation/design/frontend-architecture.md`

## 问题描述

用户在操作过程中 token 过期，往往在下一次 API 调用才触发 401/403；此时已编辑内容可能丢失，且用户不知道“发生了什么/下一步怎么做”。

## 技术分析

- 现状：
  - `POST /v1/task-codes/redeem` 返回 `expires_at`（见 `src/api/task_codes.py` 与 `frontend/src/api/client.ts` 的 `RedeemTaskCodeResponse`/mock）。
  - 前端目前只存储 token（`frontend/src/state/storage.ts` 的 `ss.auth.v1.{jobId}`），未持久化 `expires_at`，也没有定时检测。
  - `frontend/src/api/client.ts` 在 401/403 时会清除 token，但 UI 仅在失败发生后才提示。
- 风险：Step3 等页面存在本地未提交输入（answers/variable mappings）；过期后再失败会造成“无声数据丢失”的体验。

## 解决方案

1. 在 `frontend/src/state/storage.ts` 为 auth 增加元信息持久化（例如新增 key `ss.auth.v1.{jobId}.meta`，保存 `expires_at`）。
2. 在页面壳（或 App 级组件）加入定时检测（例如每 30 秒检查一次）：
   - 剩余 ≤ 5 分钟：展示“会话即将过期”提示条（不遮挡主流程）。
   - 剩余 ≤ 0：提示已过期并引导用户续期/重新兑换。
3. 提供“续期”按钮：
   - 优先策略：再次调用 `POST /v1/task-codes/redeem`（同 task_code + requirement），更新 token + expires_at（后端已返回 `is_idempotent`，允许安全重试/续期语义）。
   - 续期成功后不刷新页面、不丢失当前本地输入。
4. 与 FE-038 联动：在续期前后都应保证 Step3 表单状态可持久化恢复，避免任何失败路径导致输入丢失。

## 验收标准

- [ ] 会话过期前 5 分钟出现明确提示（包含剩余时间或“即将过期”）
- [ ] 点击“续期”可获得新 token 并继续流程（不刷新、不丢 Step3 本地输入）
- [ ] 过期后触发 401/403 时：清理 token 并给出明确引导（重新兑换/续期），不静默丢数据

## Dependencies

- FE-038（表单状态持久化）
