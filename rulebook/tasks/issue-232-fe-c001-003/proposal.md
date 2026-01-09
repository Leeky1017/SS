# Proposal: issue-232-fe-c001-003

## Why
SS 目前的 Desktop Pro 前端是单文件 `index.html`，难以维护与演进；同时后续闭环步骤需要一个稳定的 typed API client 与可刷新恢复的本地状态模型。

## What Changes
- 新增独立 `frontend/`（Vite + React + TypeScript）。
- 迁移 Desktop Pro 样式基线（CSS variables + primitives + light/dark toggle），不引入新视觉体系。
- 增加 typed API client（base url、request id、Bearer token 注入、401/403 统一处理、结构化错误模型）。
- 实现 Step 1 “开启智能化分析”（redeem task code → `{job_id, token}` → localStorage 持久化 → 刷新恢复）。

## Impact
- Affected specs:
  - `openspec/specs/ss-frontend-desktop-pro/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`
- Affected code:
  - `frontend/**` (new)
  - (no backend changes required)
- Breaking change: NO
- User benefit: Desktop Pro UI 可持续演进；错误定位可追踪（request id）；用户可从 Step 1 稳定进入闭环并支持刷新恢复。
