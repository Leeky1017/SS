# Design: Robustness strategy rules (ss-full-auto-orchestration)

## Goals

- 建立一个可解释、可扩展的稳健性策略规则库：根据主回归类型（OLS/FE/DID/PSM/RDD/IV）推荐稳健性检验组合。
- 定义 `RobustnessStrategyService` 的输入/输出接口，使其可被 `FullPipelinePlanGenerator` 直接调用并插入 plan steps。
- 支持“规则为主、LLM 为辅”：默认确定性输出；仅在必要时用 LLM 做补充解释/排序，但不得生成不可验证的内容。

## Constraints (non-negotiable)

- 必须可审计：策略产出必须能追溯到规则命中原因（rule id / reason）。
- 必须有上限：稳健性 steps 数量必须受 `max_robustness_checks` 等约束控制。
- 必须可降级：缺少前提条件时必须跳过并记录原因（而不是“想当然”）。
- 模板选择必须来自模板库：禁止发明不存在的 `template_id`（参见 `assets/stata_do_library/`）。

## Core concept: Robustness bundle

稳健性策略输出不是“一个检验”，而是一个 **bundle**（集合），每个元素是一条候选 step：

```json
{
  "strategy_version": 1,
  "main_design": "ols | fe | did | psm | rdd | iv",
  "candidates": [
    {
      "check_id": "winsorize_1_99",
      "title": "缩尾处理（1%/99%）",
      "step_type": "robustness_check",
      "template_hint": {"template_id": "TA01"},
      "requires": ["primary_dataset"],
      "reason": "ols_base + outliers_risk",
      "priority": 10
    }
  ]
}
```

`template_hint` 的含义：
- v1 只提供 `template_id` 提示；最终执行层仍由 `DoTemplateSelectionService`/模板契约物化决定参数与产物。

## Rule engine interface（建议接口）

建议新增领域服务（示意）：

- `src/domain/robustness_strategy_service.py`
  - `suggest(main_design, analysis_spec, data_schema, constraints) -> RobustnessStrategy`
  - `to_plan_steps(strategy, *, depends_on_step_id) -> list[PlanStep]`

其中：
- `main_design`：来自研究设计识别或用户确认（OLS/FE/DID/PSM/RDD/IV）
- `analysis_spec`：从 draft/confirmation 提取的结构化分析意图（见 `plan_contract`）
- `data_schema`：列名、样本量、面板结构等
- `constraints`：`max_robustness_checks`、`max_steps` 等

## Recommended bundles（规则库 v1）

> v1 的目标是覆盖 **OLS/FE（P0）**，并为 DID/PSM/RDD/IV（P1）预留清晰扩展点。

### OLS（截面回归）

基础组合（按优先级建议）：
1. 缩尾/去极值（如 TA01 / TA04 类）
2. 控制变量增减（可配置）
3. 替换核心解释变量 / 被解释变量（需要用户提供替代变量或可从数据字典推断）
4. 标准误稳健（HC/cluster；取决于数据结构）

### FE（固定效应/面板）

基础组合：
1. 不同聚类层级（entity / time / two-way）或稳健标准误（按可用性）
2. 改变固定效应组合（one-way vs two-way）
3. 样本稳健性：平衡面板 vs 非平衡面板（若可行）

### DID（双重差分）

扩展组合（P1）：
1. 平行趋势检验（事件研究 / leads & lags）
2. 安慰剂（伪政策时点/伪处理组）
3. PSM-DID（若支持）
4. 控制组/样本窗口稳健性

### PSM / RDD / IV（P1）

扩展组合（P1）：
- PSM：不同匹配方法/卡尺/邻居数；平衡性检验
- RDD：不同带宽/多项式阶数；McCrary 密度检验；伪阈值
- IV：弱工具检验；过度识别检验；替代工具变量（若可）

## Decision policy（去重与约束）

建议规则输出后应用统一策略：
- 去重：同一 check_id 只保留一次
- 前提校验：`requires` 不满足则跳过并记录 `skipped_reason`
- 数量上限：按 `priority` 从高到低截断
- 依赖设置：稳健性 steps 默认依赖主回归 step（`depends_on=[main_regression]`）

## Integration points（代码对齐点）

- 插入计划：
  - `src/domain/plan_generation_llm.py`（Prompt 可引用规则输出作为“候选清单”）
  - `src/domain/plan_service_llm_builder.py`（物化步骤参数）
- 执行与产物：
  - `src/domain/composition_exec/executor.py`
  - `src/domain/composition_exec/summary.py`

