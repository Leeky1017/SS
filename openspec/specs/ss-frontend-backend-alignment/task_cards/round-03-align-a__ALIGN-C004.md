# [ROUND-03-ALIGN-A] ALIGN-C004: draft preview/patch/confirm 的 Step3 合同对齐（含阻断项后端校验 + pytest）

## Problem

Step 3 目前存在“前端降级可用”的路径：后端缺字段/缺 patch/缺阻断校验时，前端会隐藏面板或放行确认。
这会导致：
- 合同漂移：字段名/字段是否存在不稳定
- 安全与一致性风险：阻断项仅在前端校验可被绕过
- 无法写出稳定的 user-journey tests（因为后端行为不确定）

## Goal

把 Step 3 v1 合同在后端彻底对齐并写死：
- `GET /v1/jobs/{job_id}/draft/preview` 返回 draft-v1 字段全集（含 202 pending）
- `POST /v1/jobs/{job_id}/draft/patch` 支持 `field_updates` 并返回 patch-v1 响应
- `POST /v1/jobs/{job_id}/confirm` 接收并持久化 `answers` 与 `expert_suggestions_feedback` 等字段
- 后端强制阻断校验：未完成 stage1/open_unknowns 时 confirm 必须拒绝（稳定错误码）

## In scope

- Draft preview
  - 实现 200 ready 与 202 pending（字段名与 shape 按 v1 合同）
  - `stage1_questions`/`open_unknowns` 必须存在（允许为空数组）
- Draft patch
  - 实现 `field_updates` → 更新 unknowns → 返回 `remaining_unknowns_count` + `draft_preview`
- Confirm
  - 请求字段齐全（按 v1 合同，允许空对象）
  - 阻断项校验（后端强制）
  - 持久化确认 payload，并参与 plan/contract identity（plan id）以保证可复现
- Pytest：覆盖 preview/patch/confirm 的核心分支与阻断失败路径

## Out of scope

- 前端 UI 改动
- LLM 质量优化与更复杂的风险评估算法
- Step 3 以外的流程扩展（Step 4/5）

## Dependencies

- ALIGN-C001（Step3 v1 合同）
- ALIGN-C002（token 链路）
- ALIGN-C003（job 路由鉴权覆盖）

## Acceptance

- [ ] `GET /v1/jobs/{job_id}/draft/preview`：
  - [ ] 200 响应包含 draft-v1 关键字段：`decision`、`risk_score`、`data_quality_warnings`、`stage1_questions`、`open_unknowns`
  - [ ] 202 响应使用 v1 固定 pending shape（含 `retry_after_seconds`）
- [ ] `POST /v1/jobs/{job_id}/draft/patch` 支持 `field_updates` 并返回 v1 固定字段：`patched_fields`、`remaining_unknowns_count`、`open_unknowns`、`draft_preview`
- [ ] `POST /v1/jobs/{job_id}/confirm`：
  - [ ] 缺失阻断项时返回 400 + `DRAFT_CONFIRM_BLOCKED`
  - [ ] 阻断项已解决时返回 200（至少含 `job_id`、`status`、`message`）
  - [ ] `answers` 与 `expert_suggestions_feedback` 等确认 payload 被持久化并参与 plan id
- [ ] `ruff check .` 通过
- [ ] `pytest -q` 通过，覆盖成功与阻断失败路径

