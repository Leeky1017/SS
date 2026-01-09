# [ROUND-02-FE-A] FE-B001: Step 3 Draft Preview 加载 + 预处理中状态

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
- Legacy reference:
  - `legacy/stata_service/frontend/src/components/ConfirmationStep.tsx`
  - `legacy/stata_service/frontend/src/api/stataService.ts`

## Problem

`index.html` 的 Step 3 “分析蓝图预检”当前为静态表格，缺少：
- 与后端 `draft/preview` 的真实数据对接
- 对 HTTP 202（pending/timeout）的 UX 处理（提示 + 自动重试）

## Goal

让 Step 3 成为真实可交互的“预检入口”：进入页面即可加载 Draft Preview，并对 pending 状态提供稳定可理解的用户体验。

## In scope

- 在 Step 3 进入时调用 `GET /v1/jobs/{job_id}/draft/preview`（支持 `main_data_source_id`）
- 显式处理：
  - 200：渲染草案字段（outcome/treatment/controls）与基础信息（decision/status/risk）
  - 202：显示“预处理中”，按 `retry_after_seconds` 自动重试
  - 非 2xx：显示可恢复错误，并允许用户重试
- 不引入新的视觉系统：复用 `panel`/`section-label`/`btn`/`mono`

## Out of scope

- 变量纠偏 UI（见 FE-B002）
- 澄清/待确认项 UI（见 FE-B003）
- 确认与锁定（见 FE-B004）

## Dependencies & parallelism

- Depends on: backend 提供结构化 `DraftPreviewResponse`（见 `openspec/specs/backend-stata-proxy-extension/spec.md`）
- Can run in parallel with: FE-B005（warnings UI 结构）

## Acceptance checklist

- [ ] Step 3 进入时必定触发 draft preview 请求（含可选 `main_data_source_id`）
- [ ] HTTP 202 显示“预处理中”并按 `retry_after_seconds` 自动重试（不显示为错误）
- [ ] 错误态可恢复（明确提示 + 重试按钮），且不会卡死在不可操作状态
- [ ] UI 仍符合现有 `index.html` 设计语言（不引入新框架/新组件库）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md` 记录关键命令与输出

