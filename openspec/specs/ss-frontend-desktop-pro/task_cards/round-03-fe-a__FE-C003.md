# [ROUND-03-FE-A] FE-C003: Step 1（Create job）+ 本地状态持久化（支持刷新恢复）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`

## Problem

没有 Step 1（创建 job），用户无法开始闭环；同时缺少状态持久化会导致刷新/崩溃后丢失 `job_id`，无法恢复流程。

## Goal

实现 Step 1 “开启智能化分析”：用户输入需求 → 创建 job 成功 → 进入 Step 2，并把关键状态持久化以支持刷新恢复。

## In scope

- UI 严格复刻 `index.html` 的 Step 1（文案、布局、`section-label`/`btn`/`mono`）
- Create job：
  - `POST /v1/jobs`（requirement）
  - 成功后在 UI 显示 `job_id`（可复制）
- 本地状态持久化（localStorage，刷新可恢复）：
  - `job_id`
  - requirement 文本
  - Task Code（如用户填写，用于 `X-SS-Tenant-ID`）
  - 当前 step/view
- 错误态（可恢复）：创建失败显示结构化错误 + request id + 重试按钮

## Out of scope

- 上传与预览（Step 2，见 FE-C004）
- Blueprint 预检与确认（Step 3，见 FE-C005）
- 状态/产物页（见 FE-C006）

## Dependencies & parallelism

- Depends on: FE-C001、FE-C002
- Can run in parallel with: FE-C006（状态页），但需要统一的本地状态模型

## Acceptance checklist

- [ ] Step 1 UI 复刻 `index.html` 的 Desktop Pro 风格（primitives + CSS 变量语义一致）
- [ ] `POST /v1/jobs` 成功后可进入 Step 2，且 `job_id` 可复制
- [ ] 刷新页面后可恢复到同一 `job_id` 的流程位置（不会丢失 job 上下文）
- [ ] 失败时展示结构化错误 + request id，并可重试
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

