# [BACKEND] Stata Proxy Extension — Proxy Layer 功能补齐（变量纠偏 + 结构化草案预览 + 冻结前列名校验）

## Background

SS 新后端在 Execution Engine（`src/domain/composition_exec/` 等）已成熟，但 Proxy Layer（API + domain service）仍缺少旧版 `stata_service` 已验证的关键交互语义：
- confirm 时提交变量纠偏（variable corrections），并保证后续冻结/计划/Do-file 一致
- 草案预览返回结构化字段（outcome/treatment/controls + 候选列 + 类型/数据源），可直接驱动 UI
- 契约冻结前做列名交叉验证，阻断不存在的变量进入可执行阶段

本 task card 用于追踪“实现工作”，权威行为以 OpenSpec 为准：`openspec/specs/backend-stata-proxy-extension/spec.md`。

## Goal

实现 backend proxy extension 的三项能力：variable corrections、structured draft preview、contract freeze validation，使确认与冻结链路可复现、可审计、可测试。

## In scope (v1)

- **API payload**：
  - `POST /v1/jobs/{job_id}/confirm` 接收并持久化 `variable_corrections: dict[str,str]` 与 `default_overrides: dict[str,JsonValue]`
  - `GET /v1/jobs/{job_id}/draft/preview` 返回结构化字段（保持 `draft_text` 向后兼容）
- **Domain behavior**：
  - variable corrections 清洗规则（trim / drop empty / drop identity），并使用 *token-boundary* 正则替换（避免子串误伤）
  - corrections 必须应用到确认后“有效字段”（requirement/draft 结构字段等），使 plan/do-file 与 UI 一致
  - freeze 前列名交叉验证：纠偏后的变量名必须存在于 primary dataset 列集合，否则拒绝冻结/排队
  - `plan_id` 必须包含 confirmation payload（含 `variable_corrections` / `default_overrides`），保证幂等与可解释的冲突语义
- **Tests**：
  - unit：token-boundary 替换边界条件与幂等性
  - integration：confirm 携带纠偏后，生成/执行前链路使用纠偏后的变量名；冻结校验失败返回稳定错误码

## Out of scope

- 前端 UI（`index.html`）与交互逻辑（本卡仅后端）
- 改动 Execution Engine 的核心执行流水线（除“将纠偏后的有效输入”传入下游所需的最小改动）
- 方法论升级（建模/统计口径）与模板库优化

## Dependencies & parallelism

- Related specs:
  - `openspec/specs/backend-stata-proxy-extension/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`
  - `openspec/specs/ss-job-contract/spec.md`
  - `openspec/specs/ss-llm-brain/spec.md`
- Parallelizable with: frontend confirmation UX（只要 endpoint 契约一致即可并行）

## Acceptance checklist

- [ ] `ConfirmJobRequest` / `JobConfirmation` 增加并持久化 `variable_corrections` 与 `default_overrides`
- [ ] Variable corrections 清洗规则实现且可测试（trim/drop-empty/drop-identity）
- [ ] Token-boundary 替换实现且不误伤子串（`col_a` 不影响 `col_a2`）
- [ ] `DraftPreviewResponse` 返回结构化字段：`outcome_var` / `treatment_var` / `controls[]` / `column_candidates[]` / `variable_types[]` / `data_sources[]` / `default_overrides`
- [ ] `freeze_plan` 在写入 `artifacts/plan.json` 前完成列名交叉验证；失败返回 HTTP 400 + `error_code="CONTRACT_COLUMN_NOT_FOUND"`，且 job 不进入 `queued`
- [ ] `plan_id` 在 confirmation payload 变化时必然变化（包含纠偏与 overrides），一致输入保持幂等
- [ ] Tests 通过并留证：`ruff check .`、`pytest -q`、`openspec validate --specs --strict --no-interactive`
