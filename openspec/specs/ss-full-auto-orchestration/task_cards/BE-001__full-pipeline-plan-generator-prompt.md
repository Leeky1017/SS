# Task Card: BE-001 FullPipelinePlanGenerator Prompt 设计

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`
  - `openspec/specs/ss-llm-brain/spec.md`

## 问题描述

当前 `plan.generate` 的 Prompt 更偏“单模板/通用规划”，缺少“完整实证链路”的标准骨架与约束，导致：
- LLM 输出经常只包含 1 个主回归步骤，或缺少稳健性/机制/异质性规划
- step 语义不稳定（难以聚合、难以 UI 展示、难以写论文段落）

## 技术分析

- 影响：`composition_exec` 的多步能力无法释放；用户无法一次性得到“论文可粘贴材料”，系统仍停留在“代跑回归”层级。
- 代码定位锚点：
  - `src/domain/plan_generation_llm.py`（`build_plan_generation_prompt`）
  - `src/domain/models.py`（`PlanStepType` / `LLMPlan`）
  - `src/domain/plan_service_llm_builder.py`（`generate_plan_with_llm` 的输入与物化方式）

## 解决方案

1. 设计并实现一个“完整链路规划 Prompt 骨架”，至少包含：
   - 标准实证链路模板（描述→主回归→稳健×N→机制→异质→输出）
   - 明确的约束：`max_steps`、`max_robustness_checks`、允许的 step types、`step_id` 规范
   - 强制输出：**仅 JSON**（无 markdown、无额外文本）
2. 将 Prompt 与 `PlanGenerationInput` 对齐：
   - 可用模板清单（SELECTED_TEMPLATES）
   - 数据结构摘要（DATA_SCHEMA）
   - draft/confirmation 关键上下文（但禁止泄露敏感信息）
3. 为“阶段语义稳定”增加强制约束：
   - `purpose` 必须包含可用于 UI/聚合的短语（如 “主回归（基准）”“稳健性：缩尾”）
   - 稳健性/机制/异质性步骤必须声明 `depends_on`（至少依赖主回归）

## 验收标准

- [ ] Prompt 内显式包含标准链路模板骨架，并强制 LLM 仅返回 JSON
- [ ] Prompt 明确列出允许的 step types 与 `step_id` 规则，避免自由发挥
- [ ] 在不修改执行层的前提下，LLM 输出可被现有解析器校验通过（或为下一任务 BE-002 提供兼容升级点）

## Dependencies

- 无

