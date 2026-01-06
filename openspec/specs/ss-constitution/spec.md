# Spec — SS constitution (canonical engineering law)

## Goal

把 SS 的工程约束、分层边界、数据契约与交付纪律固化为 OpenSpec：后续所有实现 Issue 都必须以本 spec 为“圣旨”，并在各自的 spec 中显式引用与继承这些硬约束。

## Context

SS 的目标是“LLM 作为大脑的 Stata 实证分析自动化系统”。如果不先把边界、契约与验收方式固定，后续功能迭代会自然滑向：
- 业务散落在 API routes
- 隐式依赖与全局耦合
- 异常吞掉导致不可观测
- LLM 黑箱输出不可回放/不可审计

## Requirements

### R1 — Canonical documentation lives in OpenSpec

- SS 的**权威项目文档** MUST 位于 `openspec/specs/`。
- `docs/` 目录 MUST 只作为“指针/入口”，不得承载权威约束（避免第二套文档体系）。

### R2 — Follow repository hard constraints

- 所有实现 MUST 遵守仓库 `AGENTS.md` 的硬约束（分层、依赖注入、异常与日志、尺寸上限等）。
- 禁止动态代理/隐式转发（`__getattr__`、延迟 import 绕循环依赖等）。

### R3 — Architecture contracts are binding

下列契约 MUST 作为全系统一致口径（细节见本目录的补充文档）：
- 分层与依赖方向：`api -> domain -> ports <- infra`（以及独立 worker）
- 数据契约：`job.json` v1（含 `schema_version`）与 artifacts 索引
- 状态机与幂等键：合法迁移、并发写入策略、重试语义
- LLM Brain：结构化 `LLMPlan`、prompt/response artifacts、脱敏与安全边界
- Stata Runner：do-file 生成、执行隔离、日志与产物归档

### R4 — Legacy reference policy

- 旧 `stata_service` MAY 作为“需求与边界案例”参考来源。
- 实现 MUST NOT 复刻旧工程的架构模式（动态代理、全局单例、超大 routes 文件、吞异常）。

## Scenarios (verifiable)

### Scenario: canonical docs are under openspec

Given the repository on `main`  
When browsing `openspec/specs/ss-constitution/`  
Then the SS constitutional docs exist and `docs/` only contains pointers to them.

### Scenario: future work uses spec-first

Given a new Issue introduces behavior changes  
When its PR is created  
Then it includes a spec under `openspec/specs/**/spec.md` and it references the SS constitution in its Requirements.

## Links

- Constitution docs index: `openspec/specs/ss-constitution/README.md`
- Roadmap: `openspec/specs/ss-constitution/09-roadmap.md`

