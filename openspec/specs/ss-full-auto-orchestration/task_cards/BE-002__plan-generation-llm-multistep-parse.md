# Task Card: BE-002 plan_generation_llm.py 增强（多步解析）

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`
  - `openspec/specs/ss-llm-brain/spec.md`

## 问题描述

全链路规划需要更强的“可解析 + 可校验”护栏：
- 计划必须是多步 JSON schema（版本化）
- 需要支持扩展 step 类型（例如 `mechanism_analysis`）
- 解析失败必须产生稳定的 `error_code`，并支持降级/回退策略（而不是 silent failure）

## 技术分析

- 影响：LLM 输出轻微漂移就会导致计划冻结失败，或生成不可执行 plan，阻断全自动链路。
- 代码定位锚点：
  - `src/domain/plan_generation_llm.py`（`build_plan_generation_prompt` / `parse_plan_generation_result`）
  - `src/domain/models.py`（`PlanStepType` / `PlanStep` / `LLMPlan` 校验）
  - `src/domain/plan_service_llm_builder.py`（LLM steps → 可执行 steps 的物化）

## 解决方案

1. 扩展 plan generation response schema（保持版本化）：
   - 支持新增 step type：`mechanism_analysis`（或兼容降级：`generate_stata_do` + `purpose` 标注）
   - 如需新增字段（例如 `pipeline_template_version`），必须在 schema 中显式定义并 `extra="forbid"`
2. 强化解析与校验：
   - 支持从 markdown fenced code block 中提取 JSON（兼容 LLM 偶发输出）
   - 校验：JSON object、`steps[]` 非空、`max_steps` 上限、`step_id` 安全、`depends_on` 引用存在、允许的 `type`
3. 失败路径必须稳定可验收：
   - 每类失败使用明确 `error_code`（例如 `PLAN_GEN_JSON_INVALID` / `PLAN_GEN_SCHEMA_INVALID` / `PLAN_GEN_UNSUPPORTED_STEP_TYPE`）
   - 解析失败时，上层要么返回结构化错误，要么走 rule fallback，并记录 `fallback_reason`
4. 补齐单元测试（优先放在 `tests/test_plan_generation_llm.py`）：
   - happy path：5+ steps + 新类型（或 purpose 标注）可解析
   - error path：非法 JSON / 超过 max_steps / 不支持 type / 不安全 step_id

## 验收标准

- [ ] `parse_plan_generation_result` 对全链路多步 JSON 的解析与校验通过，且支持兼容 code fence
- [ ] 新增/调整的解析失败返回稳定 `error_code`（测试断言）
- [ ] 解析输出可被 `LLMPlan` 校验通过（作为执行层物化的前置条件）

## Dependencies

- BE-001

