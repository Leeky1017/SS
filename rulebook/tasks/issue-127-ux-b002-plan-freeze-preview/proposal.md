# Proposal: issue-127-ux-b002-plan-freeze-preview

## Why
Worker 执行依赖 `job.llm_plan`，但当前 HTTP 用户路径从未冻结 plan，导致 worker 报 `PLAN_MISSING`，生产就绪 UX 闭环无法完成。

## What Changes
- 在确认/入队前自动冻结 plan（`POST /v1/jobs/{job_id}/confirm` / `POST /v1/jobs/{job_id}/run`）。
- 新增 plan 冻结与预览 API：
  - `POST /v1/jobs/{job_id}/plan/freeze`
  - `GET /v1/jobs/{job_id}/plan`
- plan 持久化与审计：写入 `job.json` + `artifacts/plan.json`，并在 `artifacts_index` 索引 `kind=plan.json`。

## Impact
- Affected specs: `openspec/specs/ss-ux-loop-closure/task_cards/round-01-ux-a__UX-B002.md`
- Affected code: domain/job lifecycle + API routes + tests
- Breaking change: NO（仅新增 endpoint / 增强门禁）
- User benefit: 用户可预览 plan，确认后入队不再触发 `PLAN_MISSING`。

