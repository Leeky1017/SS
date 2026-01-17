# Task Card: BE-009 Plan freeze error detail

- Priority: P1-HIGH
- Area: Backend / Errors
- Design refs:
  - `openspec/specs/ss-ux-remediation/design/backend-api-enhancements.md`
  - `openspec/specs/ss-api-surface/spec.md`

## 问题描述

当前 `PLAN_FREEZE_MISSING_REQUIRED` 虽然已经返回结构化字段（`missing_fields`/`missing_params`/`next_actions`），但仍缺少“缺什么/候选是什么/如何补全”的用户可操作细节，前端难以渲染直观的补全 UI，用户只能看到笼统报错。

## 技术分析

- 现状：
  - 错误类型：`PlanFreezeMissingRequiredError`（`src/infra/plan_exceptions.py`）会将 `missing_fields`、`missing_params` 与 `next_actions` 合并进响应。
  - API 测试已断言这些字段存在（见 `tests/test_plan_api.py`）。
- 缺口：
  - `missing_fields` 目前是 `list[str]`（字段路径），缺少对用户友好的 `description` 与可选 `candidates`。
  - `missing_params` 目前是占位符列表（例如 `__NUMERIC_VARS__`），前端无法知道如何让用户补齐，或该从哪里取候选。

## 解决方案

1. 保持现有字段兼容（不破坏现有客户端与测试）：继续返回 `missing_fields: list[str]` 与 `missing_params: list[str]`。
2. 新增可选增强字段（非 breaking）：
   - `missing_fields_detail: [{ field: str, description: str, candidates: list[str] }]`
   - `missing_params_detail: [{ param: str, description: str, candidates: list[str] }]`
   - `action: str`（例如“请在前端选择缺失变量后重试”）
3. `next_actions` 强化：为每个 action 明确 `type`/`label`/`payload_schema`（前端可直接渲染按钮与表单）。
4. 前端（FE-043/FE-046/BE-008 联动）解析上述结构并渲染可操作 UI，而不是只显示红字报错。

## 验收标准

- [ ] 错误响应仍包含 `error_code` 与 `message`，且不暴露内部异常堆栈
- [ ] 错误响应包含可操作的缺失项增强结构（detail 字段），不破坏现有字段
- [ ] 前端可基于该结构直接渲染补全 UI（下拉候选 + 重试按钮）

## Dependencies

- 无
