# [ROUND-03-ALIGN-A] ALIGN-C003: jobs 路由鉴权覆盖策略落地（含兼容 POST /v1/jobs + pytest）

## Problem

即使 redeem 与 token 存在，如果 `/v1/jobs/{job_id}/...` 路由不一致地强制鉴权，前端仍会遇到：
- 某些端点未校验 token（安全边界被绕过）
- 401/403 错误码不稳定（前端无法稳定处理；测试无法锁回归）
- 现有 `POST /v1/jobs` 的兼容策略不明确（灰度/迁移不可控）

## Goal

在 FastAPI 层落地 v1 鉴权覆盖范围与错误码集合：
- 对 redeem 创建的 job：所有 `/v1/jobs/{job_id}/...` 端点强制 `Authorization: Bearer <token>`
- `POST /v1/jobs` 默认保留，但可通过 `SS_V1_ENABLE_LEGACY_POST_JOBS=0` 禁用
- 401/403 返回稳定 `error_code`（集合按 v1 合同写死）

## In scope

- API deps：实现 Bearer header 解析 + token 校验（显式依赖注入，不使用隐式代理）
- 路由覆盖：将鉴权依赖接入 v1 job-scoped 路由（至少覆盖 spec 列举端点）
- 兼容策略：实现 `SS_V1_ENABLE_LEGACY_POST_JOBS` 控制 `POST /v1/jobs` 是否可用
- 错误码：按 v1 合同固定 401/403 的 `error_code` 集合
- Pytest：补齐 missing-token / wrong-token 的拒绝路径测试（锁 `error_code`）

## Out of scope

- 非 job-scoped 的全局鉴权体系
- 账号体系与多租户权限模型（跨 job 的 ACL）
- 速率限制与审计增强（另开卡）

## Dependencies

- ALIGN-C001（v1 合同冻结）
- ALIGN-C002（token 存储/校验能力）

## Acceptance

- [ ] redeem 创建的 job：以下端点缺 token 返回 401 + `AUTH_BEARER_TOKEN_MISSING`
  - [ ] `POST /v1/jobs/{job_id}/inputs/upload`
  - [ ] `GET /v1/jobs/{job_id}/draft/preview`
  - [ ] `POST /v1/jobs/{job_id}/draft/patch`
  - [ ] `POST /v1/jobs/{job_id}/confirm`
- [ ] wrong token 返回 403，且 `error_code` 属于 v1 固定集合（`AUTH_TOKEN_INVALID`/`AUTH_TOKEN_FORBIDDEN`）
- [ ] `SS_V1_ENABLE_LEGACY_POST_JOBS=0` 时，`POST /v1/jobs` 返回 403 + `LEGACY_POST_JOBS_DISABLED`
- [ ] `ruff check .` 通过
- [ ] `pytest -q` 通过，并锁定 401/403 的 `error_code` 行为

