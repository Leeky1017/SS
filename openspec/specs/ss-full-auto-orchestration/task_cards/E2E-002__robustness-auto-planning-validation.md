# Task Card: E2E-002 稳健性自动规划验证

- Priority: P0
- Area: E2E
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/design/robustness-strategy-rules.md`
  - `openspec/specs/ss-full-auto-orchestration/spec.md`

## 问题描述

需要 E2E 验证：当主回归类型为特定设计（至少 OLS/FE，扩展到 DID 等）时，系统会自动插入稳健性 steps，而不是只跑主回归。

## 技术分析

- 影响：稳健性是全自动代劳的核心缺口之一；若策略插入失败，会导致交付物缺失论文必要环节。
- 代码定位锚点：
  - `src/domain/models.py`（`PlanStepType.ROBUSTNESS_CHECK`）
  - `src/domain/plan_service_llm_builder.py`（插入/物化 plan 的关键路径）
  - `src/domain/composition_exec/summary.py`（验证稳健性 step 是否执行）

## 解决方案

1. 在 `tests/e2e/` 增加稳健性规划用例：
   - 构造一个明确为 OLS/FE 的分析需求（或通过 confirmation/draft 结构字段表达）
2. 断言：
   - plan steps 中存在 `robustness_check`（至少 1 个）
   - 执行后 `composition_summary.json` 中存在对应 step 且 status 非空
3. 扩展（可选）：
   - DID 输入触发 DID-specific check（Phase 2/扩展后启用）

## 验收标准

- [ ] OLS/FE 用例必定插入 `robustness_check` steps（断言 step types）
- [ ] 多步执行 summary 中可见稳健性 step 的 run_id 与产物引用
- [ ] 若缺少前提条件，测试断言系统给出可审计 skip reason（而非悄悄不做）

## Dependencies

- BE-005

