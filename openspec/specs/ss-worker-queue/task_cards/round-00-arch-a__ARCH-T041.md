# [ROUND-00-ARCH-A] ARCH-T041: Queue 抽象 + file-based 实现（claim）

## Metadata

- Issue: #22 https://github.com/Leeky1017/SS/issues/22
- Epic: #13 https://github.com/Leeky1017/SS/issues/13
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-worker-queue/spec.md`

## Goal

实现最小队列机制，保证同一 job 只会被一个 worker claim；同时保持可替换为 DB/Redis 等。

## In scope

- domain 定义 Queue/Claimer 端口（或在 infra 定义但依赖明确）
- file-based 实现：使用原子 rename/lock 实现 claim
- claim 失败/过期策略明确

## Dependencies & parallelism

- Hard dependencies: #16 + #17（job 状态口径与持久化边界）
- Parallelizable with: #19 / #20 / #24

## Acceptance checklist

- [ ] claim 原子化：不会双 worker 同时拿到同一 job
- [ ] 过期/失败策略明确且可测试
- [ ] 测试覆盖：并发 claim（多进程/线程或模拟）与幂等
- [ ] `openspec/_ops/task_runs/ISSUE-22.md` 记录关键命令与输出
