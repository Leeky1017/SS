# SS 宪法（Constitution）— Index

本目录是 SS 的权威工程文档（OpenSpec）。后续实现必须以这里的契约为准；`docs/` 仅保留指针。

## 目录

宪法（总纲）：
- `openspec/specs/ss-constitution/spec.md`：本宪法的强制性要求（MUST/SHOULD）
- `openspec/specs/ss-constitution/01-principles.md`：原则与边界（分层、依赖注入、异常/日志）

Contract specs（按模块拆分，供 agent 定向阅读）：
- `openspec/specs/ss-delivery-workflow/spec.md`：协作与交付流程门禁（Issue→PR→Checks→Auto-merge）
- `openspec/specs/ss-roadmap/spec.md`：路线图与 task_cards（Issue 蓝图）
- `openspec/specs/ss-job-contract/spec.md`：job.json v1 / workspace / artifacts index
- `openspec/specs/ss-state-machine/spec.md`：状态机、幂等与并发一致性
- `openspec/specs/ss-ports-and-services/spec.md`：ports/services 边界与可测试拆分
- `openspec/specs/ss-api-surface/spec.md`：API 契约（薄层 + status/artifacts/run）
- `openspec/specs/ss-llm-brain/spec.md`：LLMPlan、trace artifacts、脱敏与安全边界
- `openspec/specs/ss-worker-queue/spec.md`：worker/queue/claim/run attempts/retry
- `openspec/specs/ss-stata-runner/spec.md`：StataRunner、do-file 生成、执行隔离与产物
- `openspec/specs/ss-do-template-library/spec.md`：Do 模板库（legacy tasks）复用策略与边界
