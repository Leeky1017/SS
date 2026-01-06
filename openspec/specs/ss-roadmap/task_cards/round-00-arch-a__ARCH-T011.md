# [ROUND-00-ARCH-A] ARCH-T011: 定义 job.json v1 schema + Pydantic models

## Metadata

- Issue: #16 https://github.com/Leeky1017/SS/issues/16
- Epic: #10 https://github.com/Leeky1017/SS/issues/10
- Roadmap: #9 https://github.com/Leeky1017/SS/issues/9
- Related specs:
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-ports-and-services/spec.md`

## Goal

把 `job.json` v1 固化为可验证的 schema（含 `schema_version`），并用 Pydantic 模型承载（domain 层），确保读写边界明确。

## In scope

- `job.json` v1 字段清单与语义（含兼容/迁移策略）
- domain 层 Pydantic 模型：Job、Draft、ArtifactRef、RunAttempt、LLMPlan（按需拆分）
- JobStore load/save 的 schema_version 校验（如需要含升级策略）

## Out of scope

- 引入真实数据库/对象存储（仍可用文件系统 store）
- 引入真实 LLM provider 或真实 Stata 执行

## Acceptance checklist

- [ ] `job.json` v1 字段清单 + 语义说明文档完整
- [ ] Pydantic 模型覆盖并保持文件 `< 300` 行（必要时拆分）
- [ ] load/save 对 schema_version 行为明确（校验/拒绝/升级）
- [ ] 单元测试覆盖：合法/缺字段/错误类型/损坏 JSON
- [ ] `openspec/_ops/task_runs/ISSUE-16.md` 记录关键命令与输出

## Evidence

- Run log: `openspec/_ops/task_runs/ISSUE-16.md`
- Local gates:
  - `openspec validate --specs --strict --no-interactive`
  - `ruff check .`
  - `pytest -q`

