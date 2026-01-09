# [ROUND-02-FE-A] FE-B004: Confirm 执行确认 + 契约锁定（Contract Lockdown）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/frontend-stata-proxy-extension/spec.md`
- Related specs:
  - `openspec/specs/ss-ux-loop-closure/spec.md`
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
- Legacy reference:
  - `legacy/stata_service/frontend/src/components/ConfirmationStep.tsx`
  - `legacy/stata_service/frontend/src/api/stataService.ts`

## Goal

用户点击确认后，系统提交确认信息并进入只读锁定态，明确告知“需求已确认，任务已加入执行队列”，避免重复修改与重复确认造成语义混乱。

## In scope

- Confirm gating：只有在 FE-B002（纠偏）与 FE-B003（阻断项）满足后才允许确认
- Confirm 请求：
  - `POST /v1/jobs/{job_id}/confirm`
  - body 包含：`answers`、`variable_corrections`（以及 v1 空对象 `default_overrides`、`expert_suggestions_feedback`）
- 风险确认：
  - 当 `decision=require_confirm_with_downgrade` 时必须弹窗二次确认
- 锁定态：
  - 禁用变量纠偏与澄清输入
  - 显示锁定 banner 文案
  - 提供“查看任务状态/下载结果”导航到 query view

## Out of scope

- Job 执行进度轮询与 artifacts 下载（不属于本 spec 的拆分范围）

## Dependencies & parallelism

- Depends on: FE-B002 / FE-B003
- Depends on: 后端 confirm 行为与 plan-freeze/queue 规则（见 `openspec/specs/ss-ux-loop-closure/spec.md`）

## Acceptance checklist

- [ ] 所有阻断项完成前，确认不可达（disabled 或明确校验提示）
- [ ] confirm 请求 payload 含 `answers` 与 `variable_corrections`，字段名与 spec 一致
- [ ] downgrade 风险时，必须显式二次确认才会发出 confirm 请求
- [ ] confirm 成功后进入锁定态：输入禁用 + banner + 可导航到查询页
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-<N>.md` 记录关键命令与输出

