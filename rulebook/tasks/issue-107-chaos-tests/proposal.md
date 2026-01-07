# Proposal: issue-107-chaos-tests

## Why
SS 需要在资源耗尽/依赖不可用等极端条件下仍能给出清晰错误、避免数据损坏，并留下可审计证据；当前缺少覆盖这些失效模式的确定性测试与部分写入失败的清理保障。

## What Changes
- 新增 `tests/chaos/` 混沌工程测试与显式故障注入 fixtures。
- 强化文件写入的失败清理（避免磁盘满/权限失败时遗留临时文件或部分 artifact）。
- 提供可测试的 LLM 自动 failover 适配器（主 LLM 长期不可用时 fallback）。

## Impact
- Affected specs:
  - `openspec/specs/ss-testing-strategy/task_cards/chaos.md`
  - `openspec/specs/ss-testing-strategy/README.md`
  - `openspec/specs/ss-observability/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
- Affected code:
  - `src/infra/job_store.py`
  - `src/infra/llm_tracing.py`
  - `src/infra/llm_failover.py` (new)
  - `tests/chaos/*` (new)
- Breaking change: NO
- User benefit: 资源异常时返回稳定可读错误；数据不被部分写入破坏；日志/证据完整可追溯。
