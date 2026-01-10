# [ROUND-01-PROD-A] PROD-E2E-R011: 在 v1 旅程中执行模板选择（不再硬编码）

## Metadata

- Priority: P0
- Issue: #328
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F001)
- Related specs:
  - `openspec/specs/ss-do-template-library/spec.md`
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

在 `/v1` 旅程中，通过 `DoTemplateSelectionService` 选择真实 `template_id`，并持久化选择证据（stage1/stage2/candidates artifacts），确保模板选择“可解释、可复现（证据）、非硬编码”。

## In scope

- 选择触发点固定为：`GET /v1/jobs/{job_id}/draft/preview`（E2E 审计旅程已包含该步骤）。
- 选择结果必须落盘为 artifacts（复用 `DoTemplateSelectionService` 现有 evidence 写入机制）。
- 选择出的 `selected_template_id` 必须持久化到 job，以供 plan freeze 使用（plan freeze 不再写死 template）。

## Out of scope

- 合并 draft preview 与 template selection 为单次 LLM 调用（可后续优化，但本任务先跑通最小链路）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R010`（catalog/repo wiring）
- Soft dependencies: `PROD-E2E-R041`（移除 stub LLM 前需确保真实 LLM provider 链路可用）

## Acceptance checklist

- [ ] `draft/preview` 之后，job 进入可 plan-freeze 的状态且包含 `selected_template_id`
- [ ] artifacts 中可见 selection 证据（stage1/candidates/stage2）且模型信息可审计
- [ ] `openspec/_ops/task_runs/ISSUE-<N>.md` 记录一次真实运行的证据（下载 artifacts 截图/路径即可）
