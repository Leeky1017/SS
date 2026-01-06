# Proposal: issue-16-arch-t011-job-json-v1

## Why
`job.json` 是 SS 端到端链路的“唯一权威索引”，必须先把 v1 合同固化为可验证的 schema（含 `schema_version`）并在读写边界强校验，避免后续 worker/LLM/stata 等模块在不一致数据上演化。

## What Changes
- ADDED: `job.json` v1 领域模型（Pydantic）与关键校验（schema_version / rel_path）。
- MODIFIED: File-based `JobStore` 在 load/save 时做 schema_version 校验，并将结构校验失败视为数据损坏。
- MODIFIED: `ss-job-contract` 文档补齐字段清单与语义说明。
- ADDED: 单元测试覆盖合法/缺字段/错误类型/损坏 JSON。

## Impact
- Affected specs: `openspec/specs/ss-job-contract/`
- Affected code: `src/domain/models.py`, `src/infra/job_store.py`, `src/domain/job_service.py`, `tests/`
- Breaking change: YES (缺失/未知 `schema_version` 的 job.json 将被拒绝)
- User benefit: 合同可验证、迁移可控、错误更早暴露且可审计
