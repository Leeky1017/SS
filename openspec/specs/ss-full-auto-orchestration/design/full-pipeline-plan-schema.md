# Design: Full pipeline plan schema (ss-full-auto-orchestration)

## Goals

- 定义“完整实证链路”的 **多步 LLMPlan** 结构（可冻结、可回放、可执行）。
- 定义标准实证链路模板：描述 → 主回归 → 稳健性×N → 机制（可选）→ 异质（可选）。
- 定义需要扩展的 step 类型（特别是 `mechanism_analysis`），并明确与现有 `composition_exec` 的对齐点。

## Non-goals

- 不在本设计文档内定义每一种模板（do-file）实现细节（模板库由 `assets/stata_do_library/` 管理）。
- 不在本设计文档内定义“研究设计推荐”的完整方法论（那属于 `ResearchDesignService` 的后续扩展）。

## Context（现状与约束）

- 当前可执行计划以 `src/domain/models.py` 的 `LLMPlan`/`PlanStep` 为准，并由 `PlanService` 冻结到：
  - `job.json` 的 `job.llm_plan`
  - `artifacts/plan.json`（并入 artifacts index）
- `composition_exec` 要求计划满足：
  - `step_id` 安全（路径段安全）
  - `depends_on[]` 构成有效 DAG
  - do 生成类 step 必须带 `template_id` / `input_bindings` / `products` 等执行参数（见 `src/domain/composition_plan.py`）

## Two-layer plan model（两层计划，避免 LLM 直接写执行细节）

### Layer A: Plan generation response（LLM 输出的“规划层”）

用于 LLM 输出、解析与校验（推荐 v1）：

```json
{
  "schema_version": 1,
  "steps": [
    {
      "step_id": "snake_case_id",
      "type": "descriptive_stats | generate_stata_do | robustness_check | mechanism_analysis | heterogeneity_analysis | data_validation",
      "purpose": "短目的描述（给用户/给聚合器）",
      "depends_on": ["prev_step_id"],
      "fallback_step_id": null,
      "params": {
        "template_id": "optional template id from selected templates"
      }
    }
  ]
}
```

约束（v1）：
- `step_id` MUST 为安全路径段（snake_case，禁止空格与 `..` 等）
- `type` MUST 是允许集合之一
- `depends_on` 引用必须存在
- `params.template_id` MAY 存在；若存在则必须是允许模板之一

### Layer B: Executable LLMPlan（系统物化后的“执行层”）

由后端把 Layer A 的“规划 step”转换为可执行的 `LLMPlan`（典型由 `src/domain/plan_service_llm_builder.py` 负责）：

```json
{
  "plan_version": 1,
  "plan_id": "sha256-like fingerprint",
  "rel_path": "artifacts/plan.json",
  "plan_source": "llm | rule | rule_fallback",
  "fallback_reason": null,
  "steps": [
    {
      "step_id": "main_regression",
      "type": "generate_stata_do",
      "purpose": "主回归（基准）",
      "depends_on": ["descriptive"],
      "params": {
        "composition_mode": "sequential | parallel_then_aggregate | ...",
        "template_id": "T17",
        "template_params": {},
        "template_contract": {},
        "input_bindings": {"primary_dataset": "input:primary"},
        "products": [
          {"product_id": "table_main", "kind": "table", "role": "main"}
        ]
      },
      "produces": ["stata.do"]
    }
  ]
}
```

说明：
- LLM 不直接生成 `template_params`/`template_contract` 等执行细节；这些由系统根据模板库与 analysis spec 物化。
- `products[]` 用于跨 step 的产物引用与聚合；与 `composition_exec` 的产物登记一致。

## Standard pipeline template（标准实证链路模板，v1）

> 该模板作为 Prompt 的“骨架”，保证不同 job 的 step 语义一致、便于聚合与写作。

### Required minimum（最小闭环，必须包含）

1. `data_validation`：数据结构/缺失值/基础诊断（可轻量）
2. `descriptive_stats`：描述统计/相关矩阵（至少生成一张表）
3. `generate_stata_do`（purpose=main_regression）：主回归（基准）
4. `robustness_check` × N：至少 1 个稳健性检验
5. `generate_stata_do`（purpose=export_and_format 或等价）：确保主要表格按用户请求格式产出

### Optional blocks（可选块）

- `mechanism_analysis` × M：中介/调节/渠道等（按 Planner 与模板可用性插入）
- `heterogeneity_analysis` × H：分组回归/交互项等（按 Planner 与模板可用性插入）

## Step type vocabulary（类型词表）

本 spec 对 step 类型的最小要求：
- `descriptive_stats`：描述性分析类
- `robustness_check`：稳健性检验类
- `heterogeneity_analysis`：异质性分析类
- `mechanism_analysis`：机制分析类（新增；需要在 `PlanStepType` 中扩展）
- `data_validation`：数据诊断类
- `generate_stata_do`：通用 do 生成（可承载主回归等）

兼容策略：
- 若短期无法引入 `mechanism_analysis` 类型，允许退化为 `generate_stata_do` + `purpose=mechanism_analysis`；
  但长期 SHOULD 以类型枚举表达，以便聚合与 UI 稳定识别。

## Composition mode guidance（编排模式建议）

- 默认：`sequential`（最可解释、最稳）
- 稳健性/异质性中彼此独立的分支：MAY 使用 `parallel_then_aggregate`（节省时间）
- 任何并行 MUST 以显式依赖与聚合 step（或聚合后处理）收敛，避免“隐式同步”

## Integration points（代码对齐点）

- Prompt/parse 层：
  - `src/domain/plan_generation_llm.py`（prompt 构造 + 解析/校验）
- 执行计划物化：
  - `src/domain/plan_service_llm_builder.py`（LLM steps → 可执行 steps）
  - `src/domain/composition_plan.py`（输入绑定/产物/依赖校验）
- 多步执行：
  - `src/domain/composition_exec/executor.py`（执行）
  - `src/domain/composition_exec/summary.py`（`composition_summary.json`）

