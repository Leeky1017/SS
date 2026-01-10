# [ROUND-01-PROD-A] PROD-E2E-R002: 只允许 task-code redeem 创建 job（移除 legacy POST /v1/jobs）

## Metadata

- Priority: P1
- Issue: #314
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F006 context)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## Goal

生产唯一 job 创建入口是：`POST /v1/task-codes/redeem`。删除 legacy `POST /v1/jobs` 以及相关开关，避免出现“另一条未审计的创建链路”。

## In scope

- 移除 `POST /v1/jobs`（以及其兼容开关 `v1_enable_legacy_post_jobs` 和相关 auth guard）。
- 更新任何使用该 legacy endpoint 的测试/脚本/文档指针为 redeem 入口。

## Out of scope

- 设计新的 job 创建权限模型（本任务只收敛入口，复用现有 token 机制）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R001`（v1-only business surface）
- Parallelizable with: do-template 相关任务

## Acceptance checklist

- [ ] `/v1` 下不存在 `POST /jobs` 的业务入口（路由/测试证据）
- [ ] E2E 审计旅程仍可通过 redeem → upload → preview → draft → freeze → run → artifacts 完成
- [ ] `openspec/_ops/task_runs/ISSUE-<N>.md` 记录移除与验证证据
