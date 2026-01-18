# Spec: ss-full-auto-orchestration

## Purpose

Define the technical specification that upgrades SS from “single-template regression runner” into a **full-auto empirical analysis concierge**: one user requirement → a multi-step pipeline plan → robust execution → aggregated results → paper-ready paragraphs → downloadable, reproducible artifacts.

本规范聚焦“全自动代劳服务”的**编排层（orchestration）**：把现有 `composition_exec` 的多步执行能力、LLM 规划能力、稳健性策略、结果聚合与论文写作串成可审计、可回放、可演进的最小闭环。

## 概述

蓝图目标（简述）：
- 用户仅提供：研究需求（自然语言）+ 数据文件
- 系统自动交付：实证结果、论文可粘贴表格、论文段落、以及完整可复现材料

当前系统已有的关键基建（与本 spec 强相关）：
- `composition_exec`：多步执行框架（DAG 依赖、产物传递、条件跳过、`composition_summary.json`）
- `PlanService`：Plan 冻结与持久化（`job.llm_plan` + `artifacts/plan.json`）
- `DraftService`：需求解析与变量角色识别（仍需增强，但不是本 spec 的主线）
- `StataReportService`：单步结果“技术解读”（需要升级为论文写作与多步聚合）

## 范围

### In scope（本 spec 覆盖）

- **完整链路规划**：`FullPipelinePlanGenerator` 生成多步 `LLMPlan`（描述→主回归→稳健×N→机制→异质→输出）
- **稳健性策略自动规划**：`RobustnessStrategyService`（规则引擎为主，LLM 辅助为辅）
- **多步结果聚合**：`ReportAggregationService`（汇总表与可粘贴材料）
- **论文段落生成**：`PaperWritingService`（方法、结果、稳健性、机制/异质性）
- **执行进度追踪**：后端进度 API + 前端展示
- **产出物打包**（可选）：`OutputPackagingService` 生成安全的 ZIP 下载包

### Out of scope（明确不在本 spec 解决）

- 全自动数据清洗/变量构造的全面覆盖（可作为后续 spec）
- 学科/期刊风格的深度定制（本 spec 仅定义最小可切换接口）
- 端到端“结果驱动策略调整”的自动科研策略探索（留作后续）

## Vocabulary (v1)

- **Full pipeline**：一次确认（confirm）触发的一条多步分析链，含稳健性/机制/异质性等可选分支。
- **LLMPlan**：可执行、可冻结、可回放的结构化计划（见 `ss-llm-brain`）。
- **Step**：Plan 内一步；必须有 `step_id`，并通过 `depends_on[]` 形成 DAG。
- **Aggregation**：把多步产物收敛为“用户可读、可粘贴”的统一报告/表格集合。
- **Paper paragraphs**：论文可用的自然语言段落；必须可追溯到具体数值来源，禁止“编数字”。

## Related specs (normative)

- Constitutional constraints: `openspec/specs/ss-constitution/spec.md`
- LLM plan + artifacts discipline: `openspec/specs/ss-llm-brain/spec.md`
- Job workspace + artifacts index: `openspec/specs/ss-job-contract/spec.md`
- JobStore optimistic concurrency: `openspec/specs/ss-job-store/spec.md`
- Domain state machine: `openspec/specs/ss-state-machine/spec.md`
- API surface + structured errors: `openspec/specs/ss-api-surface/spec.md`
- Observability baseline: `openspec/specs/ss-observability/README.md`
- Testing strategy: `openspec/specs/ss-testing-strategy/README.md`
- Stata runner boundary: `openspec/specs/ss-stata-runner/spec.md`

## Requirements

### Requirement: FullPipelinePlanGenerator MUST generate a multi-step, executable LLMPlan

SS MUST provide a `FullPipelinePlanGenerator` that produces a **multi-step** plan for a standard empirical pipeline:
- 描述性分析（至少 1 步）
- 主回归（至少 1 步）
- 稳健性检验（至少 1 步，且可配置 N）
- 机制分析/异质性分析（MAY，按可行性与约束插入）

The generated plan MUST be representable as an `LLMPlan` and MUST be executable by `composition_exec` (valid DAG dependencies, safe ids, valid bindings, and valid composition parameters).

#### Scenario: A confirmed job produces a 5+ step pipeline plan
- **GIVEN** a confirmed job with a non-empty requirement
- **WHEN** SS freezes a plan using the full-pipeline generator
- **THEN** `job.llm_plan.steps` contains 5+ steps including at least one `descriptive_stats` and at least one `robustness_check`

### Requirement: Plan generation MUST be schema-bound, validated, and auditable

Plan generation outputs used for downstream behavior MUST be schema-bound and validated. On failure, SS MUST NOT silently continue:
- If the LLM response is invalid JSON / invalid schema / unsafe ids / unsupported step types, SS MUST either:
  - fail with a structured error (`error_code` + `message`), OR
  - fall back to a rule-based plan and record `plan_source=rule_fallback` with a stable `fallback_reason`

Any fallback decision MUST be observable (structured logs) and auditable (LLM artifacts + plan artifacts).

#### Scenario: Unsupported step type triggers structured fallback
- **WHEN** the LLM returns a plan containing an unsupported step type
- **THEN** SS records `plan_source=rule_fallback` with a non-empty `fallback_reason`, and persists the LLM prompt/response artifacts per `ss-llm-brain`

### Requirement: A standard empirical pipeline template MUST anchor the prompt (not ad-hoc plans)

The plan-generation prompt MUST be anchored on a standard empirical pipeline template (描述→主回归→稳健×N→机制→异质→输出) so step semantics are stable across jobs and across models.

SS SHOULD allow bounded prompt customization via explicit inputs (e.g., `max_steps`, `max_robustness_checks`, `preferred_design`) and MUST NOT rely on free-form prompt drift.

#### Scenario: The prompt includes a canonical template skeleton
- **WHEN** reading the plan-generation prompt implementation
- **THEN** it contains an explicit “standard pipeline skeleton” section and does not rely solely on free-form natural language instructions

### Requirement: RobustnessStrategyService MUST propose robustness checks by regression type

SS MUST provide a `RobustnessStrategyService` that maps the main regression type (e.g., OLS/FE/DID/PSM/RDD/IV) to a recommended robustness-check bundle.

The robustness strategy MUST be:
- rule-based by default (deterministic, explainable)
- bounded by constraints (e.g., max checks)
- safe when prerequisites are missing (skip with reason, not hallucinate)

#### Scenario: DID triggers DID-specific robustness checks
- **GIVEN** a job whose main design is DID
- **WHEN** generating a full pipeline plan
- **THEN** the plan contains robustness steps covering at least one DID-specific check (e.g., parallel-trend / placebo / PSM-DID) or explicitly records why they were skipped

### Requirement: Mechanism/Heterogeneity planning MUST be explicit and bounded (optionally enabled)

SS MUST define an explicit and bounded mechanism/heterogeneity planning behavior. When enabled, SS SHOULD provide a `MechanismHeterogeneityPlanner` that proposes mechanism and heterogeneity steps when the requirement and data schema support them.

Any inserted steps MUST:
- be explicit (no implicit “magic” behavior)
- be bounded (cap number of steps)
- declare prerequisites and dependencies via `depends_on[]`

#### Scenario: Mechanism/heterogeneity steps are only added when feasible
- **WHEN** the requirement does not contain feasible mechanism/heterogeneity signals or required variables are missing
- **THEN** SS does not add mechanism/heterogeneity steps and records a structured reason (as artifacts and/or logs)

### Requirement: Multi-step execution MUST emit a pipeline summary artifact and stable step evidence

For any multi-step execution, SS MUST write a pipeline summary artifact (e.g., `composition_summary.json`) that includes step-level status, run ids, produced artifacts, and decisions (e.g., conditional skips).

Each step MUST have a stable evidence directory under the job workspace so users (and E2E tests) can inspect outputs.

#### Scenario: composition_summary.json exists after pipeline execution
- **WHEN** a multi-step pipeline run completes (success or failure)
- **THEN** the job artifacts index contains a `composition.summary.json` artifact and it references a readable JSON file

### Requirement: ReportAggregationService MUST aggregate multi-step outputs into a versioned schema

SS MUST provide a `ReportAggregationService` that aggregates multi-step outputs into a versioned, machine-readable structure (aggregation schema v1), including:
- step list + key outputs (tables/figures/reports)
- robustness comparison table(s)
- heterogeneity comparison table(s)
- links to the underlying artifact rel_paths

Aggregation outputs MUST be indexed in `job.json` artifacts index and MUST be reproducible from stored artifacts.

#### Scenario: Aggregation produces a stable aggregation JSON artifact
- **WHEN** a pipeline run succeeds
- **THEN** SS writes a versioned aggregation artifact (JSON) and indexes it, and the artifact includes per-step output references

### Requirement: PaperWritingService MUST generate paper-ready paragraphs with numeric traceability

SS MUST provide a `PaperWritingService` that generates paper-ready paragraphs for:
- 方法（Method）
- 主回归结果（Main results）
- 稳健性（Robustness）
- 机制/异质性（Mechanism/Heterogeneity, as applicable）

Generated paragraphs MUST be schema-bound (versioned JSON) and MUST include numeric traceability:
- If a numeric claim is made, it MUST be traceable to an aggregation/step artifact (no fabricated numbers).
- If required numbers are missing, the service MUST output explicit placeholders (e.g., “（待补）”) instead of guessing.

#### Scenario: Paper paragraphs never fabricate numeric results
- **WHEN** the writing service cannot find required numbers in aggregated artifacts
- **THEN** it emits placeholders and a structured reason, and still persists artifacts for audit

### Requirement: Progress tracking MUST be exposed via a stable API contract

SS MUST expose pipeline progress so the frontend can render “第 k/n 步：<purpose>”:
- progress MUST be derived from persisted artifacts / run state (not transient in-memory state)
- API MUST remain thin and return structured errors (per `ss-api-surface`)
- state changes MUST remain domain state-machine driven (per `ss-state-machine`)

#### Scenario: Client can query step-level progress
- **WHEN** a client requests job progress for a running pipeline
- **THEN** the response includes total steps, current step index (or running step_id), and per-step status without leaking internal stack traces

### Requirement: Output packaging MUST be safe and reproducible (if enabled)

SS MUST ensure that any output packaging is path-safe (no traversal, no symlink escape) and is indexed as an artifact.

SS MAY provide an `OutputPackagingService` to produce a single downloadable ZIP containing:
- plan + pipeline summary
- do/log outputs (step evidence)
- aggregated report + summary tables
- paper paragraphs (md/docx)

#### Scenario: ZIP packaging is path-safe
- **WHEN** requesting a ZIP bundle download
- **THEN** SS rejects unsafe paths and returns `{"error_code":"...","message":"..."}` without exposing internals

### Requirement: Observability MUST cover plan, pipeline, aggregation, and writing lifecycles

SS MUST emit structured logs (JSON line) for:
- plan generation start/done/fallback
- each step start/done/fail (with `job_id`, `run_id`, `step_id`)
- aggregation start/done/fail
- paper writing start/done/fail

#### Scenario: Key events are traceable in logs
- **WHEN** a full pipeline job is executed
- **THEN** logs contain stable `event` codes covering plan generation, step execution, aggregation, and writing, each with `job_id`

