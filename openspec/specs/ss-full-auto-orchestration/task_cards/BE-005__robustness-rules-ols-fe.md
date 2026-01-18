# Task Card: BE-005 稳健性规则库实现（OLS/FE基础）

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/robustness-strategy-rules.md`
  - `openspec/specs/ss-do-template-library/spec.md`

## 问题描述

需要先把最常见的主回归类型（OLS/FE）覆盖到“可自动规划”的稳健性组合，否则全自动链路无法满足论文最低要求。

## 技术分析

- 影响：没有基础规则库，稳健性只能依赖 LLM 自由发挥，输出不可控、不可测、不可审计。
- 代码定位锚点：
  - `src/domain/do_template_repository.py`（模板索引/读取）
  - `src/domain/do_template_plan_support.py`（模板参数与 analysis vars 支持）
  - `src/domain/models.py`（`PlanStepType.ROBUSTNESS_CHECK`）

## 解决方案

1. 在规则库中实现 OLS/FE 的最小稳健性组合（v1）：
   - 缩尾/去极值（如 TA01/TA04 类）
   - 替代标准误/聚类层级（按数据结构可用性）
   - 控制变量增减（可配置）
   - 固定效应组合变化（FE 专属）
2. 每条规则必须提供：
   - `check_id`、`reason`、`requires`、`template_hint.template_id`
3. 输出必须可约束：
   - `max_robustness_checks` 截断
   - 去重（check_id 唯一）
4. 补齐单元测试：
   - 对 OLS/FE 输入返回稳定候选列表（按 priority 排序）
   - 缺少必要变量/数据结构时跳过并记录原因

## 验收标准

- [ ] OLS/FE 输入可返回 2+ 条稳健性候选（受 max 限制）
- [ ] 规则输出确定性（同输入 → 同输出顺序与内容）
- [ ] 单元测试覆盖：OLS/FE、缺少前提条件的降级与 reasons

## Dependencies

- BE-004

