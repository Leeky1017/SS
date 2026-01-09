# [ROUND-03-FE-A] FE-C006: Job 状态页 + Artifacts 列表/下载（对齐 ss-job-contract 的“可下载产物”定义）

## Metadata

- Priority: P0
- Issue: #N
- Spec: `openspec/specs/ss-frontend-desktop-pro/spec.md`
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-ux-loop-closure/spec.md`

## Problem

完成确认后，用户必须能看到状态推进并下载产物，否则闭环无法完成；同时 artifacts 的呈现必须与 `ss-job-contract` 对齐，避免路径/类型误解。

## Goal

实现 Job 状态页（查询视图）与 artifacts 列表/下载：用户可输入/选择 `job_id` 查询状态，轮询直到完成，并能下载至少一个产物文件（含日志/结果表等）。

## In scope

- Job 状态：
  - `GET /v1/jobs/{job_id}` 渲染 status、timestamps、draft summary、latest_run summary
  - 支持轮询与手动刷新（可展示上次刷新时间）
- Artifacts：
  - `GET /v1/jobs/{job_id}/artifacts` 渲染 artifacts 列表（kind/rel_path/meta）
  - `GET /v1/jobs/{job_id}/artifacts/{artifact_id:path}` 支持下载（注意 URL encoding 与文件名展示）
  - UI 与 `ss-job-contract` 的 artifact 概念对齐（rel_path 是 job-relative；kind 为枚举词汇）
- 错误态（可恢复）：请求失败显示结构化错误 + request id + 重试

## Out of scope

- 复杂的 artifacts 预览器（例如在线查看 log/表格）
- Worker 执行调度策略展示

## Dependencies & parallelism

- Depends on: FE-C002、FE-C001
- Can run in parallel with: FE-C003–FE-C005（但需要共享 job_id 与本地状态恢复逻辑）

## Acceptance checklist

- [ ] Job 状态页可查询并展示 `GET /v1/jobs/{job_id}` 的关键字段（含轮询/刷新）
- [ ] Artifacts 列表可展示并下载至少一个文件（`/artifacts` + `/artifacts/{artifact_id:path}`）
- [ ] artifacts 呈现与 `ss-job-contract` 对齐（kind + job-relative `rel_path` 的语义正确）
- [ ] 错误态可恢复（清晰提示 + request id + 重试）
- [ ] Evidence: `openspec/_ops/task_runs/ISSUE-N.md` 记录关键命令与输出

