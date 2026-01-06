# [ROUND-00-ARCH-A] ARCH-T012: 状态机 guard + 幂等键（revision/fingerprint）

## Metadata

- Issue: #17 https://github.com/Leeky1017/SS/issues/17
- Epic: #10 https://github.com/Leeky1017/SS/issues/10
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-state-machine/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`

## Goal

把状态机推进规则与幂等策略写成 domain 逻辑（可测试），避免 routes/worker 各写一套。

## In scope

- 状态枚举与允许迁移表（created→draft_ready→confirmed→queued→running→succeeded|failed）
- 幂等键定义与计算方式：inputs fingerprint + requirement（规范化）+ plan revision（如适用）
- 非法迁移返回结构化错误（SSError 子类）并记录事件码

## Out of scope

- 分布式锁/数据库事务（先保证 file-store 最小正确性）

## Acceptance checklist

- [ ] 状态机迁移规则在 domain 中集中定义
- [ ] 非法迁移返回结构化错误（含 error_code）且有事件码日志
- [ ] 幂等策略可解释且有单元测试
- [ ] 单元测试覆盖：合法迁移、非法迁移、重复请求幂等
- [ ] `openspec/_ops/task_runs/ISSUE-17.md` 记录关键命令与输出

## Evidence

- Run log: `openspec/_ops/task_runs/ISSUE-17.md`

