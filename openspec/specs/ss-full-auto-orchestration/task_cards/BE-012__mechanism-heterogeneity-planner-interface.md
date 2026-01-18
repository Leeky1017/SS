# Task Card: BE-012 MechanismHeterogeneityPlanner 接口

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`
  - `openspec/specs/ss-full-auto-orchestration/spec.md`

## 问题描述

机制与异质性属于“全自动代劳服务”从 P0 走向 P1 的关键扩展。当前缺少一个可插拔的 Planner 来：
- 识别可行的机制路径（中介/调节/渠道）
- 识别可行的分组维度（异质性）
- 将这些分析以明确的 steps 插入 full pipeline plan

## 技术分析

- 影响：没有 Planner，机制/异质性只能靠人工多次调用；系统无法从“稳健性闭环”进一步提升到“论文完整闭环”。
- 代码定位锚点：
  - `src/domain/plan_generation_llm.py`（step types 解析与校验）
  - `src/domain/models.py`（`PlanStepType` 需要扩展或兼容标注）
  - `src/domain/plan_service_llm_builder.py`（steps 物化为可执行步骤）

## 解决方案

1. 新增领域接口（建议新文件）：
   - `src/domain/mechanism_heterogeneity_planner.py`
2. Planner 输出建议：
   - `mechanism_steps[]`：每个包含 `step_id/type/purpose/depends_on/params`
   - `heterogeneity_steps[]`：同上
   - 每个候选必须带 reason + prerequisites
3. 与 full pipeline plan 的集成策略（v1）：
   - Planner 作为 `FullPipelinePlanGenerator` 的可选依赖注入（显式依赖，不做隐式 import）
   - 若 planner 无法产出可行步骤，必须返回空列表并记录原因
4. 兼容性：
   - 若引入 `mechanism_analysis` 作为新 `PlanStepType`，同步更新解析/校验与物化路径

## 验收标准

- [ ] Planner 接口定义清晰且可单测（同输入 → 同输出/同 reasons）
- [ ] 插入的 steps 满足 DAG 依赖与 `step_id` 安全规则
- [ ] 缺少前提条件时安全降级（返回空 steps + reasons），不抛裸异常

## Dependencies

- BE-002

