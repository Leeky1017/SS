# [ROUND-01-UX-A] UX-B002: 确认前冻结 Plan + 对外可预览

## Metadata

- Issue: #127 https://github.com/Leeky1017/SS/issues/127
- Audit: #124 https://github.com/Leeky1017/SS/issues/124
- Priority: P0 (Blocker)
- Related specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-state-machine/spec.md`

## Goal

把 `PlanService.freeze_plan()` 接入用户链路，确保“仅依赖 API + worker”即可完成从确认到执行的闭环，并让用户能查看和理解将要执行的计划（plan）。

## In scope

- 在确认（confirm/submit）路径中自动冻结 plan（或新增显式 plan-freeze 端点并在 confirm 前强制）
- plan 必须同时：
  - 写入 `job.json` 的 `llm_plan`
  - 写入 artifact `artifacts/plan.json`（kind: `plan.json`）并进入 artifacts index
- 提供 plan 预览能力：
  - 可通过 API 直接查看 plan（或通过 artifacts index 下载）
- 幂等与冲突：
  - 重复 confirm/plan-freeze 幂等
  - 冻结冲突必须结构化报错（禁止 silent）
- 更新用户旅程测试：不再直接调用 `PlanService.freeze_plan`

## Dependencies & parallelism

- Depends on: `PlanService`（ARCH-T031, #20 已完成）
- Depends on: state machine（created/draft_ready/confirmed 口径）
- Parallelizable with: `UX-B001` / `UX-B003`

## Acceptance checklist

- [ ] 用户确认链路会冻结 plan，并持久化到 job.json + artifacts/plan.json
- [ ] 用户可预览 plan（API 或 artifacts download）
- [ ] 重复提交幂等；冲突路径返回结构化错误
- [ ] user journey tests 改为纯 HTTP 流程（不直调 PlanService）
