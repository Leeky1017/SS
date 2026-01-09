# [ROUND-03-UPLOAD-A] UPLOAD-C006: pytest 并发覆盖（create session / finalize）+ stress/bench 计划

## Metadata

- Priority: P1
- Issue: #N
- Spec: `openspec/specs/ss-inputs-upload-sessions/spec.md`
- Related specs:
  - `openspec/specs/ss-testing-strategy/README.md`
  - `openspec/specs/ss-observability/spec.md`

## Problem

高并发是 upload-sessions 的核心风险面：如果没有可重复的并发测试与最小压测门禁，finalize 可能在竞争条件下损坏 inputs/manifest.json 或产生不一致指纹。

## Goal

用 pytest + anyio 覆盖并发创建会话与并发 finalize 的关键分支，并提供一份最小的 stress/bench 计划与证据记录口径。

## In scope

- pytest 并发测试（anyio）：
  - 并发 `POST /v1/jobs/{job_id}/inputs/upload-sessions`
  - 并发 `POST /v1/upload-sessions/{upload_session_id}/finalize`
  - 断言：幂等结果一致、manifest 不损坏、fingerprint 稳定
- Fake object store adapter 支撑并发（来自 UPLOAD-C002）
- Stress/bench 计划（不要求进入 CI 的重压）：
  - 维度：会话创建并发、finalize 并发、不同 part_size/part_count
  - 指标：P50/P95 延迟、失败率、重试率、CPU/IO 粗粒度观察
- 证据记录口径：
  - 所有关键命令/输出写入 `openspec/_ops/task_runs/ISSUE-N.md`

## Out of scope

- CI 真上传 GB 级大文件
- 引入专门的压测框架（先用最小脚本/pytest 兜底）

## Dependencies & parallelism

- Depends on: UPLOAD-C002, UPLOAD-C004, UPLOAD-C005
- Can run in parallel with: 无（收口卡）

## Acceptance checklist

- [ ] pytest 并发用例覆盖 create session + finalize 的关键竞争条件
- [ ] anyio 并发测试在 CI 中稳定可复现（不依赖真实对象存储）
- [ ] 提供 stress/bench 计划与明确验收标准，并在 `openspec/_ops/task_runs/ISSUE-N.md` 留证据

