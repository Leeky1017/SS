# [ROUND-01-PROD-A] PROD-E2E-R040: 引入 production gate（startup + /health/ready 严格检查）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F004)
- Related specs:
  - `openspec/specs/ss-production-e2e-audit/spec.md`
  - `openspec/specs/ss-security/spec.md`

## Goal

在生产模式下，服务必须“缺依赖即不就绪”，避免把 stub/fake 当作生产能力。

## In scope

- 定义明确的 production 模式开关（例如 `SS_ENV=production`），并在启动与 readiness 中统一判断。
- `/health/ready` 必须对关键依赖做真实检查：
  - LLM provider 非 stub 且具备必要配置
  - runner 真实可用（已配置 `SS_STATA_CMD`）
  - upload object store 非 fake 且具备必要配置（如选择 s3）

## Out of scope

- 扩展为完整的运维自检系统（先覆盖审计门禁所需最小集合）。

## Dependencies & parallelism

- Hard dependencies: none
- Parallelizable with: do-template 相关任务

## Acceptance checklist

- [ ] 生产模式下：缺少关键配置时 `/health/ready` 返回 not ready（证据：日志 + 响应体）
- [ ] 非生产模式（如 tests）不强制要求真实外部依赖（但仍需显式配置/注入）
- [ ] 增加测试覆盖：production gate 的 ok/failed 分支

