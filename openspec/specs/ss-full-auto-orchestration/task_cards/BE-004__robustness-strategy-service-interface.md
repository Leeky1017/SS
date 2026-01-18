# Task Card: BE-004 RobustnessStrategyService 接口定义

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/robustness-strategy-rules.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`
  - `openspec/specs/ss-llm-brain/spec.md`

## 问题描述

稳健性检验是“全自动代劳服务”的核心缺口：系统必须能根据主回归类型自动规划稳健性组合。当前缺少一个明确的领域接口，导致：
- 只能靠 Prompt “碰运气”生成稳健性步骤
- 难以保证覆盖、可解释性与可测试性

## 技术分析

- 影响：稳健性无法自动规划会让交付物缺少论文关键环节，用户仍需人工多次迭代。
- 代码定位锚点：
  - `src/domain/plan_service_llm_builder.py`（LLM steps 物化为执行 steps）
  - `src/domain/plan_contract.py`（从 draft/confirmation 抽取 analysis spec 的入口）
  - `src/domain/models.py`（`PlanStepType.ROBUSTNESS_CHECK`）

## 解决方案

1. 新增领域服务接口（建议新文件）：
   - `src/domain/robustness_strategy_service.py`
2. 定义最小输入/输出（v1）：
   - 输入：`main_design`（ols/fe/did/psm/rdd/iv）、`analysis_spec`、`data_schema`、`constraints`
   - 输出：`RobustnessStrategy`（版本化）+ 一组候选 checks（含 reason、requires、template_hint）
3. 定义“插入 plan”的辅助方法：
   - `to_plan_steps(..., depends_on_step_id=main_regression_step_id) -> list[PlanStep]`
4. 补齐接口级单元测试：
   - 空输入/缺少前提条件时返回空列表并带 skip reason（不抛异常）

## 验收标准

- [ ] `RobustnessStrategyService` 接口与数据结构版本化且可序列化（JSON 友好）
- [ ] 输出包含 rule id / reason 等可审计字段
- [ ] 单元测试覆盖：正常返回、缺少前提条件的安全降级

## Dependencies

- BE-001

