# [ROUND-00-ARCH-A] ARCH-T021: 新增 GET /jobs/{job_id}（权威状态与摘要）

## Metadata

- Issue: #18 https://github.com/Leeky1017/SS/issues/18
- Epic: #11 https://github.com/Leeky1017/SS/issues/11
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

提供一个最小但权威的查询端点，支撑轮询与调试，不泄漏实现细节。

## In scope

- 新增 endpoint：`GET /jobs/{job_id}`，返回：status、timestamps、draft 摘要、artifacts 索引摘要、最近 run attempt（如有）
- API 层只做 schema/响应组装；业务读取在 domain service；持久化通过 JobStore
- 错误码映射：JOB_NOT_FOUND 等

## Dependencies & parallelism

- Hard dependencies: #16（job.json v1 + models）
- Soft dependencies: #17（如果本端点需要复用统一状态枚举/guard）
- Parallelizable with: #21 / #24

## Acceptance checklist

- [ ] endpoint 存在且响应字段满足契约
- [ ] API 薄层：不写业务 if/else，不做 IO 细节
- [ ] 测试覆盖：happy path + not found + corrupted data
- [ ] `openspec/_ops/task_runs/ISSUE-18.md` 记录关键命令与输出
