# SS 宪法（Constitution）— Index

本目录是 SS 的权威工程文档（OpenSpec）。后续实现必须以这里的契约为准；`docs/` 仅保留指针。

## 目录

- `openspec/specs/ss-constitution/spec.md`：本宪法的强制性要求（MUST/SHOULD）
- `openspec/specs/ss-constitution/01-principles.md`：原则与边界（分层、依赖注入、异常/日志）
- `openspec/specs/ss-constitution/02-job-and-artifacts.md`：job.json v1 与 artifacts 规范
- `openspec/specs/ss-constitution/03-state-machine-and-idempotency.md`：状态机、幂等与并发
- `openspec/specs/ss-constitution/04-ports-and-services.md`：ports/services 拆分（可测试的业务骨架）
- `openspec/specs/ss-constitution/05-llm-brain.md`：LLMPlan、trace artifacts、脱敏与安全边界
- `openspec/specs/ss-constitution/06-worker-queue.md`：worker/queue/claim/run attempts
- `openspec/specs/ss-constitution/07-stata-runner.md`：StataRunner、do-file、执行隔离与产物
- `openspec/specs/ss-constitution/08-api-contract.md`：API 契约（保持薄层）
- `openspec/specs/ss-constitution/09-roadmap.md`：Issues roadmap（Epics + 子 Issue）
- `openspec/specs/ss-constitution/10-delivery-workflow.md`：OpenSpec × Rulebook × GitHub 协作与交付流程
- `openspec/specs/ss-constitution/11-do-template-library.md`：Do 模板库（legacy tasks）复用策略与边界
