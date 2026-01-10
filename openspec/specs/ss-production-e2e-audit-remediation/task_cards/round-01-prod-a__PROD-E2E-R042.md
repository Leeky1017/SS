# [ROUND-01-PROD-A] PROD-E2E-R042: 移除 FakeStataRunner（生产必须配置真实 Stata runner）

## Metadata

- Priority: P0
- Issue: #317
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F004)
- Related specs:
  - `openspec/specs/ss-stata-runner/spec.md`
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

运行时不再允许 “未配置 `SS_STATA_CMD` → 自动降级 FakeStataRunner”。

## In scope

- 删除 worker 中 FakeStataRunner 的 fallback 路径；未配置即明确失败（错误码稳定）。
- 测试如需 fake runner，迁移至 `tests/**` 内的 fake 实现或注入（不保留 runtime fake runner）。

## Out of scope

- 改造 Stata runner 的跨平台适配（本任务只收敛链路与门禁）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R040`（production gate）
- Parallelizable with: do-template 相关任务

## Acceptance checklist

- [x] worker 启动时若未配置 `SS_STATA_CMD`：明确失败且可诊断（日志/错误码）
- [x] E2E 审计证据中可审计真实 Stata cmd 与 exit_code
- [x] tests 不依赖 runtime fake runner（通过注入实现）

## Completion

- PR: https://github.com/Leeky1017/SS/pull/319
- Worker startup requires `SS_STATA_CMD` and fails fast with stable `error_code=STATA_CMD_NOT_CONFIGURED`.
- Runtime fake runner removed; tests use `tests/fakes/fake_stata_runner.py` via explicit injection.
- Run log: `openspec/_ops/task_runs/ISSUE-317.md`
