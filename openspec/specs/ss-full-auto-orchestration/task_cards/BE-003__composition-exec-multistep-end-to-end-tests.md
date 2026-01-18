# Task Card: BE-003 composition_exec 多步 Plan 端到端测试

- Priority: P0
- Area: Backend
- Design refs:
  - `openspec/specs/ss-full-auto-orchestration/spec.md`
  - `openspec/specs/ss-full-auto-orchestration/design/full-pipeline-plan-schema.md`
  - `openspec/specs/ss-testing-strategy/README.md`

## 问题描述

全链路规划上线前，需要一个可稳定复现的“多步执行”验证，避免：
- 计划生成/物化看似正确，但 `composition_exec` 执行期失败
- `composition_summary.json`、产物索引、step 证据目录不稳定，导致前端/聚合/写作无法依赖

## 技术分析

- 影响：没有端到端测试，任何改动都可能让多步链路悄悄坏掉；P0 能力无法保障。
- 代码定位锚点：
  - `src/domain/composition_exec/executor.py`（`execute_composition_plan`）
  - `src/domain/composition_exec/summary.py`（`composition_summary.json` schema）
  - `src/domain/worker_plan_execution.py`（单步 vs 多步路径切换）
  - `src/domain/composition_plan.py`（计划校验与输入绑定要求）

## 解决方案

1. 新增一条端到端测试（建议 `tests/e2e/layer5_execution/` 或现有 execution 测试层）：
   - 构造一个包含 5+ steps 的 `job.llm_plan`（包含 depends_on、products、input_bindings）
   - 使用 fake `StataRunner` / fake `DoFileGenerator`（避免依赖真实 Stata）
2. 断言关键产物与不变量：
   - `composition_summary.json` 必须生成并可解析
   - 每个 step 必须有 evidence_dir（`runs/<step_run_id>/...`）
   - artifacts index 必须包含 `composition.summary.json`（以及必要的 inputs manifest 产物）
3. 覆盖至少一个失败场景：
   - 中间 step 失败后 pipeline 终止，并写入 `run.error.json`（或等价错误产物）

## 验收标准

- [ ] 新增 E2E/集成测试在本地可运行且稳定（不依赖真实 Stata）
- [ ] 测试断言 `composition_summary.json` schema_version 与 steps 列表存在
- [ ] 失败路径产生结构化错误产物（`error_code` + `message`）并被测试断言

## Dependencies

- BE-002

