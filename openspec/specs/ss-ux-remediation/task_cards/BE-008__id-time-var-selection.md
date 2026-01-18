# Task Card: BE-008 ID/Time variable selection

- Priority: P0-BLOCKER
- Area: Backend / Plan freeze
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

面板回归模板需要 `__ID_VAR__` 和 `__TIME_VAR__`（或等价占位符），但当前前端缺少让用户选择的入口，后端也缺少接收并用于 plan freeze/template fill 的机制，导致错误 `PLAN_FREEZE_MISSING_REQUIRED`，阻断完整链路。

## 技术分析

- 现状：
  - Plan freeze 端点：`POST /v1/jobs/{job_id}/plan/freeze`（`src/api/jobs.py`）只接收 `FreezePlanRequest(notes, answers)`，没有变量选择字段。
  - Confirm 端点：`POST /v1/jobs/{job_id}/confirm` 接收 `ConfirmJobRequest.variable_corrections`，但 plan freeze 可能发生在 confirm 之前或独立发生。
  - `PLAN_FREEZE_MISSING_REQUIRED` 已有结构化错误（`src/infra/plan_exceptions.py`），但前端无法在缺失发生前“预先知道要选什么”。
- 核心缺口：缺少一个稳定契约让后端告诉前端“必须选择哪些变量（ID/TIME 等）以及候选值”，并让用户选择后能在 plan freeze 时生效。

## 解决方案

1. 在 `DraftPreviewResponse`（或 Plan precheck 响应）中新增 `required_variables` 字段，示例：
   - `[{ field: \"__ID_VAR__\", description: \"个体标识变量\", candidates: [...] }, ...]`
2. 前端（Step3）根据 `required_variables` 动态生成下拉选择 UI（候选来自 inputs preview / draft candidates），并在用户选择后提交到后端：
   - 方案 A：扩展 `FreezePlanRequest` 增加 `variable_corrections`（与 confirm 对齐）；
   - 方案 B：要求先 confirm 持久化选择，再 freeze 读取 job.confirmation（需要明确顺序与状态机约束）。
3. 后端在 plan freeze 时将这些选择用于模板参数填充（例如 `xtset __ID_VAR__ __TIME_VAR__`），并将最终使用值可追溯地写入 plan/artifacts。

## 验收标准

- [ ] 前端显示“请选择 ID/Time 变量”的下拉框（候选可用且可理解）
- [ ] 用户选择后通过 API 传递并在 plan freeze 中生效
- [ ] 在已选择情况下，不再出现 `PLAN_FREEZE_MISSING_REQUIRED`
- [ ] 生成脚本中的 `xtset`（或等价设置）使用用户选择的变量名

## Dependencies

- `BE-006__auxiliary-column-candidates.md` (辅助文件列纳入候选)
- `BE-007__column-name-normalization.md` (列名标准化)
