# [ROUND-03-ALIGN-A] ALIGN-C001: 冻结 v1 合同（redeem + auth + Step3）与错误码集合（纯契约）

## Problem

Desktop Pro 前端在 Step 3 已定义并依赖稳定的 `/v1` 合同（preview/patch/confirm + gating），但后端当前契约与鉴权策略未冻结，导致：
- 前端需要降级分支（缺字段/缺 patch 端点）
- 后端实现/测试无法围绕唯一“法典”收敛（错误码漂移、字段名不一致）

## Goal

产出一个**写死**的 v1 契约（对齐结果不可争议），涵盖：
- `POST /v1/task-codes/redeem`（task-code → job_id + token）
- Bearer token 鉴权覆盖范围与兼容策略（含 `POST /v1/jobs` 的可配置共存）
- Step 3 合同：`draft/preview`（含 202 pending）、`draft/patch`、`confirm`
- 401/403 的稳定 `error_code` 集合（以及 Step3 阻断失败的稳定 `error_code`）

## In scope

- 以 `openspec/specs/ss-frontend-backend-alignment/spec.md` 为唯一权威，冻结 v1：
  - 请求/响应字段名、字段是否存在、状态码与错误码集合、幂等语义
  - Step3 “阻断项策略”：后端必须强制校验 `stage1_questions` 与 `open_unknowns`
- 交叉校验字段名与示例与以下规范一致：
  - `openspec/specs/frontend-stata-proxy-extension/spec.md`
  - `openspec/specs/ss-api-surface/spec.md`

## Out of scope

- 任何代码实现（API/domain/infra）
- entitlement/配额/计费体系
- 前端实现改动

## Dependencies

- `openspec/specs/openspec-writing-standard/spec.md`
- `openspec/specs/frontend-stata-proxy-extension/spec.md`
- `openspec/specs/ss-api-surface/spec.md`

## Acceptance

- [ ] `openspec/specs/ss-frontend-backend-alignment/spec.md` 通过 `openspec validate --specs --strict --no-interactive`
- [ ] spec.md 不包含占位文本（例如：`TODO`、`TBD`、`(fill)`、`<fill...>`）
- [ ] spec.md 写死并清晰列出：
  - [ ] redeem 请求/响应字段（含 `requirement` 必存在、`token` 轮换策略、redeem 幂等）
  - [ ] Bearer 鉴权覆盖范围（明确到 /v1 路由）与 `POST /v1/jobs` 的 config 禁用策略
  - [ ] Step3 `draft/preview`（含 202 pending）、`draft/patch`、`confirm` 的 v1 JSON 合同（字段名对齐）
  - [ ] 401/403 的 `error_code` 固定集合 + Step3 阻断失败的 `error_code`

