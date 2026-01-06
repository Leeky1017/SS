# [ROUND-00-ARCH-A] ARCH-T042: Worker loop + run attempt 目录 + retry/backoff

## Metadata

- Issue: #23 https://github.com/Leeky1017/SS/issues/23
- Epic: #13 https://github.com/Leeky1017/SS/issues/13
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-worker-queue/spec.md`
  - `openspec/specs/ss-stata-runner/spec.md`

## Goal

worker 独立执行 queued job：创建 run_id、执行各 step、归档 artifacts、更新状态；失败可重试。

## In scope

- 新增 worker 入口（例如 `python -m src.worker`），可配置并可本地跑
- 每次执行生成 `runs/<run_id>/`，把日志/产物写入
- retry/backoff 与最大重试次数可配置（来自 Config）

## Acceptance checklist

- [ ] worker 可独立启动并能消费队列
- [ ] 每次 attempt 生成 run 目录并写入 meta/artifacts
- [ ] 测试覆盖：成功一次、失败后重试成功、失败到达上限
- [ ] `openspec/_ops/task_runs/ISSUE-23.md` 记录关键命令与输出

