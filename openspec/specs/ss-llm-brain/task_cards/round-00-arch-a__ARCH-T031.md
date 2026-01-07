# [ROUND-00-ARCH-A] ARCH-T031: PlanService + LLMPlan schema（确定性 stub）

## Metadata

- Issue: #20 https://github.com/Leeky1017/SS/issues/20
- Epic: #12 https://github.com/Leeky1017/SS/issues/12
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

把“主脑计划”结构化：LLMPlan 是可序列化、可验证、可冻结的执行计划；先用确定性 stub 跑通闭环。

## In scope

- LLMPlan schema（step type + params + dependencies + expected artifacts）
- PlanService：输入 job + confirmation，输出 LLMPlan 并写回 job.json（冻结）
- stub 实现不依赖网络；真实 provider 只在 infra

## Dependencies & parallelism

- Hard dependencies: #16（job 合同）+ #17（状态机/幂等口径）
- Parallelizable with: #19 / #22 / #24

## Acceptance checklist

- [x] LLMPlan schema 与 PlanService 行为清晰（冻结、可回放）
- [x] stub 不触网，可在 CI 稳定运行
- [x] 单元测试覆盖：plan 生成、冻结、重复生成幂等
- [x] `openspec/_ops/task_runs/ISSUE-20.md` 记录关键命令与输出

## Completion

- Status: Done
- PR: https://github.com/Leeky1017/SS/pull/53
- Run log: `openspec/_ops/task_runs/ISSUE-20.md`
- Summary: LLMPlan schema + deterministic PlanService stub + tests
