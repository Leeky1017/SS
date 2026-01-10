# [ROUND-01-PROD-A] PROD-E2E-R001: 移除非 `/v1` 业务路由（只保留唯一权威 v1 链路）

## Metadata

- Priority: P0
- Issue: #297
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (inventory + F005)
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

在运行时只保留一个权威的业务 HTTP 链路：`/v1/**`。

## In scope

- 删除或停止挂载所有非 `/v1` 的 **业务** endpoints（至少包含 legacy `/jobs/**` 与其子路由）。
- 保证 `/v1` 的 auth/guards 是唯一需要维护的业务门禁（无“绕过 v1 的第二套入口”）。
- 如保留 `/health/*` 与 `/metrics`（运维面），必须明确其不承载业务能力且不掩盖生产依赖缺失。

## Out of scope

- 引入 `/v2` 或多版本并存策略（此任务目标是单一权威链路）。

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: `PROD-E2E-R040`（生产门禁）、`PROD-E2E-R010`（do-template wiring）

## Acceptance checklist

- [x] 运行时不再存在非 `/v1` 的 jobs/draft/bundle/upload-session 等业务 endpoints（代码与路由证据）
- [x] `openspec/_ops/task_runs/ISSUE-297.md` 记录路由清单与验证命令输出（含 `rg`/`curl`/OpenAPI 证据）
- [x] `openspec/specs/ss-production-e2e-audit/spec.md` 的 inventory 任务在新的现实下仍可执行并产出清晰证据

## Completion

- PR: https://github.com/Leeky1017/SS/pull/300
- Run log: `openspec/_ops/task_runs/ISSUE-297.md`
- Summary:
  - Remove legacy unversioned `/jobs/**` business surface at runtime.
  - Keep ops endpoints (`/health/*`, `/metrics`) mounted separately from business routers.
  - Add tests to prevent reintroducing non-`/v1` business routes.
