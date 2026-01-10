# [ROUND-01-PROD-A] PROD-E2E-R012: Plan freeze 输出显式契约（params / deps / outputs contract）

## Metadata

- Priority: P0
- Issue: #333
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F002)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## Goal

让 `POST /v1/jobs/{job_id}/plan/freeze` 返回的 `plan.json` 成为可执行的“显式契约”，至少包含：

- `template_id`（来自 selection）
- 参数绑定契约（required/optional + bound values + missing list）
- 依赖声明（ado/SSC/built-in 等）
- outputs/artifacts contract（模板 meta outputs + 归档路径约束）

## In scope

- Plan freeze 从被选模板的 `meta.json` 中抽取 `dependencies` 和 `outputs` 并写入 plan step params。
- Plan freeze 写入 plan artifact（仍为 `artifacts/plan.json`）并在 API 响应中返回相同信息。

## Out of scope

- 引入新的 plan schema version（优先在现有 plan step `params` 内扩展字段）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R010`、`PROD-E2E-R011`
- Parallelizable with: `PROD-E2E-R030`（缺参错误路径）

## Acceptance checklist

- [x] 下载的 `artifacts/plan.json` 显式包含 dependencies 与 outputs contract（字段固定、可审计）
- [x] Plan freeze 的响应中可见相同契约信息
- [x] 单元测试覆盖：模板 meta 缺失/损坏时的结构化错误与上下文

## Completion

- PR: https://github.com/Leeky1017/SS/pull/337
- `POST /v1/jobs/{job_id}/plan/freeze` 在 `generate_do` step params 写入 `template_contract`（params/deps/outputs contract）并落盘到 `artifacts/plan.json`
- 模板选择链路收敛到 v1 可执行子集（保证 `template_params` 可生成并避免缺参崩溃）
- 新增单测：模板 meta 缺失/损坏时返回 `PLAN_TEMPLATE_META_*` 结构化错误（含 job_id/template_id 上下文）
- Run log: `openspec/_ops/task_runs/ISSUE-333.md`
