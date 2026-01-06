# [ROUND-00-ARCH-A] ARCH-T022: Artifacts API（index+download）+ Run trigger

## Metadata

- Issue: #19 https://github.com/Leeky1017/SS/issues/19
- Epic: #11 https://github.com/Leeky1017/SS/issues/11
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

把 artifacts 作为一等公民暴露给调用方，同时提供显式 run trigger（只入队/推进状态）。

## In scope

- `GET /jobs/{job_id}/artifacts`：列出 artifacts（kind、created_at、rel_path、meta 摘要）
- `GET /jobs/{job_id}/artifacts/{artifact_id}`：安全下载（只允许 job 目录内）
- `POST /jobs/{job_id}/run`：推进到 queued 并记录 scheduled_at（或等价字段），不在 API 内执行

## Acceptance checklist

- [ ] artifacts index endpoint 与 download endpoint 都存在
- [ ] 路径安全：拒绝 `..` 与符号链接逃逸
- [ ] 重复 trigger 幂等（不重复入队/不破坏状态机）
- [ ] 测试覆盖：不安全路径、不存在 artifact、重复 trigger
- [ ] `openspec/_ops/task_runs/ISSUE-19.md` 记录关键命令与输出

