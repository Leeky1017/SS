# Task Card: E2E-001 完整链路执行验证（5步以上）

- Priority: P0
- Area: E2E
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-testing-strategy/README.md`

## 问题描述

需要一个黑盒 E2E 用例确保“全链路规划 + 多步执行”最小闭环成立：用户一次确认后，系统能生成并执行 5+ 步 pipeline，并产出可下载产物与 summary。

## 技术分析

- 影响：缺少 E2E 会让 P0 能力无法被持续验证；一旦回归，系统可能在生产中悄悄退化为单步执行。
- 代码定位锚点：
  - `src/domain/worker_plan_execution.py`（单步/多步分流）
  - `src/domain/composition_exec/executor.py`（多步执行入口）
  - `src/domain/plan_service_llm_builder.py`（多步计划物化路径）

## 解决方案

1. 在 `tests/e2e/` 新增用例（推荐放在 execution layer）：
   - 使用 fake runner（不依赖真实 Stata）执行 5+ steps
2. 断言：
   - `job.llm_plan.steps` >= 5
   - artifacts index 包含 `composition.summary.json`
   - 每步都有 evidence_dir，且至少存在 1 个表格/产物文件
3. 增加失败诊断输出：
   - 测试失败时打印关键 artifact 路径（作为证据）

## 验收标准

- [ ] E2E 用例稳定通过（可在 CI 跑，不依赖真实 Stata）
- [ ] 断言 5+ steps 与 `composition_summary.json` 存在
- [ ] 失败时输出可定位证据（不依赖人工翻日志）

## Dependencies

- BE-003

