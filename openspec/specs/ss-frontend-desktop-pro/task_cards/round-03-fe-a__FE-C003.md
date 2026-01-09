# [ROUND-03-FE-A] FE-C003: Step 1（Redeem task code）+ token 存储 + job resume（支持刷新恢复）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`

## Problem

生产默认入口需要通过 task code 兑换获得 `job_id + token`；如果没有这一步，后续 `/v1/jobs/{job_id}/**` 请求无法稳定授权，也无法支持刷新恢复。

## Goal

实现 Step 1 “开启智能化分析”：用户输入 `task_code + requirement` → redeem 成功得到 `{job_id, token}` → 持久化 token → 进入 Step 2；并支持刷新后自动恢复到最近的 job（job resume）。

## In scope

- UI 严格复刻 `index.html` 的 Step 1（文案、布局、`section-label`/`btn`/`mono`）
- Default entry (production)：
  - `POST /v1/task-codes/redeem`（`task_code + requirement`）→ `{job_id, token}`
  - redeem 成功后在 UI 显示 `job_id`（可复制），并进入 Step 2
- Dev-only fallback（必须显式门控）：
  - 通过 `VITE_REQUIRE_TASK_CODE=1` 控制：为 `1` 时不允许回退；为空/`0` 时允许回退到 `POST /v1/jobs`
  - 当用户未填写 `task_code` 或 redeem endpoint 不存在（例如 404）时，允许回退到 `POST /v1/jobs` 便于本地开发
- 本地状态持久化（localStorage，刷新可恢复）：
  - `job_id`
  - requirement 文本
  - `task_code`（如用户填写，用于 redeem）
  - token：
    - `ss.auth.v1.{job_id}` 存储 token
    - `ss.last_job_id` 存储最近一次 job_id
  - 当前 step/view
- 错误态（可恢复）：
  - redeem 失败显示结构化错误 + request id + 重试
  - 401/403（后续步骤返回）触发清理 token 并引导重新 redeem（由 FE-C002 提供统一处理能力）

## Out of scope

- 上传与预览（Step 2，见 FE-C004）
- Blueprint 预检与确认（Step 3，见 FE-C005）
- 状态/产物页（见 FE-C006）

## Dependencies & parallelism

- Depends on: FE-C001、FE-C002
- Can run in parallel with: FE-C006（状态页），但需要统一的本地状态模型

## Acceptance checklist

- [ ] Step 1 UI 复刻 `index.html` 的 Desktop Pro 风格（primitives + CSS 变量语义一致）
- [ ] redeem 成功后 token 被保存到 `ss.auth.v1.{job_id}`，且 `ss.last_job_id` 被更新；刷新页面仍能继续后续步骤
- [ ] 后续请求确实携带 `Authorization: Bearer ...`（当 token 存在时）
- [ ] 401/403 时 UI 清理 token 并提示“Task Code 已失效/未授权，需要重新兑换”，引导重新 redeem
- [ ] `VITE_REQUIRE_TASK_CODE=1` 时未填写 `task_code` 不允许回退到 `POST /v1/jobs`
- [ ] 失败时展示结构化错误 + request id，并可重试
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出
