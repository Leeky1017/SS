# [ROUND-01-PROD-A] PROD-E2E-R043: 移除 FakeObjectStore（upload sessions 生产只允许 S3）

## Metadata

- Priority: P0
- Issue: TBD
- Spec: `openspec/specs/ss-production-e2e-audit-remediation/spec.md`
- Audit evidence: `openspec/_ops/task_runs/ISSUE-274.md` (F004 context: fake object store default)
- Related specs:
  - `openspec/specs/ss-inputs-upload-sessions/spec.md`
  - `openspec/specs/ss-production-e2e-audit/spec.md`

## Goal

生产 runtime 不再允许 `SS_UPLOAD_OBJECT_STORE_BACKEND=fake`，避免 upload sessions 在生产落入“假存储”。

## In scope

- 删除 runtime 的 FakeObjectStore 与 factory 分支；生产必须使用 S3（或明确选定的唯一真实后端）。
- 对缺少 S3 配置的情况：startup/ready 明确失败（错误码稳定）。
- 测试所需 fake object store 移至 `tests/**`（通过注入）。

## Out of scope

- 引入第二种真实对象存储后端（此任务目标是收敛到唯一生产后端）。

## Dependencies & parallelism

- Hard dependencies: `PROD-E2E-R040`（production gate）
- Parallelizable with: do-template 相关任务

## Acceptance checklist

- [ ] runtime 不再支持 `fake` object store backend（错误码稳定、可诊断）
- [ ] upload sessions 流程在生产配置下可用（至少 direct/multipart 的 presign + finalize 核心路径）
- [ ] tests 不依赖 runtime fake object store（注入 fake）

