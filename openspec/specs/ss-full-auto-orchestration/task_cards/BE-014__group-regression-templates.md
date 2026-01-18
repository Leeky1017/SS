# Task Card: BE-014 分组回归模板组

- Priority: P1
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`

## 问题描述

异质性分析需要“分组回归/子样本回归”模板组。当前模板库缺少成组、可复用的分组回归模板，导致异质性 Planner 难以落地。

## 技术分析

- 影响：异质性缺失会让论文实证部分不完整，且无法达到“接近人工服务水平”的交付预期。
- 代码定位锚点：
  - `src/domain/do_template_repository.py`
  - `src/domain/do_template_plan_support.py`
  - `src/domain/models.py`（`PlanStepType.HETEROGENEITY_ANALYSIS`）

## 解决方案

1. 在 `assets/stata_do_library/` 新增分组回归模板组：
   - 按分类变量分组的子样本回归（至少支持 2 组）
   - 交互项异质性（可复用现有 T21 逻辑或封装）
2. 模板参数化要求：
   - `group_var` / `group_values` 或等价参数
   - 产物约定：每组至少导出 1 张表，便于聚合
3. 增加最小测试/校验：
   - meta schema 合法
   - 参数占位符归一化通过

## 验收标准

- [ ] 新增模板组可被索引并可在计划中被引用
- [ ] 模板契约清晰：输入参数与输出产物可预测
- [ ] 通过 do-library 相关测试与一致性检查

## Dependencies

- BE-012

